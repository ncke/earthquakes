//
//  QuakeCoordinator.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import UIKit

final class QuakeCoordinator {

    // The coordinator uses the nav controller to manage the user interface.
    weak private var navController: UINavigationController?

    // A network service to fetch features (the USGS term for a seismic event).
    private let earthquakeService = EarthquakeService()

    /// True if the coordinator is currently waiting for an ongoing network
    /// request to complete, false otherwise.
    private var isNetworkActive: Bool = false
    private let networkActivityLock = NSLock()

    // A data store to hold features.
    private let featureStore = QuakeDataStore<Feature>()

    // Filter parameter defaults.
    static private let defaultHistoricalRange: TimeInterval = 24 * 60 * 60
    static private let defaultShouldUseMinimumMagnitude = true
    static private let defaultMinimumMagnitude = 3.0

    // Filter parameter values.
    private var historicalRange = QuakeCoordinator.defaultHistoricalRange
    private var shouldUseMinimumMagnitude = QuakeCoordinator.defaultShouldUseMinimumMagnitude
    private var minimumMagnitude = QuakeCoordinator.defaultMinimumMagnitude

    // Table view controller to present the list (storyboarded).
    private weak var quakeTableViewController: QuakeTableViewController? {
        didSet {
            // Provide the table view controller with a reference to
            // the coordinate.
            guard let vc = quakeTableViewController else { return }
            vc.coordinator = self
        }
    }

    init() {
        // Populate the list upon startup.
        refreshQuakeList()
    }

    func setNavController(_ navController: UINavigationController) {
        self.navController = navController
    }

    func setQuakeTableViewController(_ vc: QuakeTableViewController) {
        // The table view controller is injected by the nav controller because
        // it is automatically created from the storyboard when the nav
        // controller is instantiated.

        quakeTableViewController = vc
    }

}

// MARK: - Seismic Event Filter Parameters

extension QuakeCoordinator {

    // We're using the getter/setter idea here to mediate access to the
    // coordinator's properties. In some situations this provides an
    // opportunity for validation, propagating data (e.g. persisting
    // parameters), or encapsulating necessary side-effects.

    func getHistoricalRange() -> TimeInterval { historicalRange }

    func setHistoricalRange(_ value: TimeInterval) {
        historicalRange = value
    }

    func getMinimumMagnitude() -> Double { minimumMagnitude }

    func setMinimummMagnitude(_ value: Double) {
        minimumMagnitude = value
    }

    func isUsingMinimumMagnitude() -> Bool { shouldUseMinimumMagnitude }

    func setUseMinimumMagnitude(_ value: Bool) {
        shouldUseMinimumMagnitude = value
    }

}

// MARK: - Refresh Availability

extension QuakeCoordinator {

    /// True if refresh functionality should be made available to the user,
    /// false otherwise.
    var isRefreshEnabled: Bool {

        // In this specific case, this is all about preventing the user
        // from mashing the 'refresh' affordances when network activity
        // is already ongoing, although the language being used here is
        // independent of networking to demonstrate that coordinated
        // instances don't have to be aware of that nuance.
        //
        // The coordinator messages when refresh should be made
        // unavailable and then available again. But some parts of the UI
        // (e.g. the QuakeTableViewSettingsCell) may not be instantiated
        // at that moment (due to cell reuse). So this provides a way
        // for those UI elements to determine their state.

        !isNetworkActive
    }

}

// MARK: - Feature Provider

// Here the coordinator is conforming to the Feature Provider protocol, but
// delegates that responsibility to the Feature Store on a method-by-method
// level. In more complex scenarios this means that the coordinator can
// be more opinionated about the data that is coming back (e.g. noticing that
// something is missing and therefore starting network activity -- or that
// could even be the responsibility of another controller object).
//
// Another alternative would be for the coordinator to provide the
// Feature Store instance itself, but 'cloaked' as a FeatureProvider to
// maintain the genericity of the protocol API. That would mean less
// boilerplate, but less control.

extension QuakeCoordinator: FeatureProvider {

    var featureCount: Int {
        featureStore.featureCount
    }

    func feature(forIndex index: Int) -> Feature? {
        featureStore[index]
    }

}

// MARK: - Detailed Features

extension QuakeCoordinator {

    // In the coordinator pattern it is the coordinator that takes
    // responsibility for presenting and dismissing user interface.

    /// Call to indicate that the user requests detailed information
    /// about an earthquake feature at the given index in the
    /// current feature list.
    func userRequestsDetail(featureIndex: Int) {
        // Instantiate a QuakeDetailViewController.

        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        guard
            let feature = feature(forIndex: featureIndex),
            let detailViewController = storyboard.instantiateViewController(
                identifier: "QUAKE-DETAIL-VC"
            ) as? QuakeDetailViewController
        else {
            return
        }

        // Configure.
        detailViewController.coordinator = self
        detailViewController.configure(feature: feature)

        // Push on to the navigation stack.
        navController?.pushViewController(detailViewController, animated: true)
    }

}

// MARK: - List Refresh

extension QuakeCoordinator {

    func refreshQuakeList() {

        // We're going to do this on a background thread. The quality-of-
        // service is user initiated because the user is going to be
        // waiting avidly for the result. We would expect the function to
        // return pretty quickly, but we are using a lock so there could
        // be momentary delays. We don't hog the log (but we might in
        // future) and table view latency is very noticeable to a user.

        DispatchQueue.global(qos: .userInitiated).async {
            self.refreshQuakeListAsync()
        }

    }

    private func refreshQuakeListAsync() {

        // This is a critical section, we want to abandon the refresh
        // if networking is already ongoing but we could get a race
        // condition if some other thread toggles the isNetworkActive
        // flag just after we've checked it. As these things go, this
        // would be pretty minor but we're choosing not to look the
        // other way this time.
        //
        // The concurrency concept that we want is an atomic test and set.

        // Start by acquiring the lock.
        networkActivityLock.lock()
        defer {
            // We actually don't need the lock until the function ends
            // because the critical section is over once the active
            // flag is set. However, the benefit of using defer is that
            // we guarantee that we release the lock (otherwise we would
            // keep other threads blocked forever, a major gotcha).
            // This is useful here because there are two ways out of the
            // critical section (normal flow and the guard). An
            // alternative to extending the lock would be to implement
            // a test-and-set helper encapsulate the details of
            // concurrency separately from the business logic.
            networkActivityLock.unlock()
        }

        guard !isNetworkActive else {
            // We're already networking, abandon the refresh.
            return
        }

        // The flag is exclusively ours to set.
        isNetworkActive = true

        // End of the critical section.

        // We've already blocked the double tap using the flag, but we need
        // to tell the user interface (back on the main thread).
        DispatchQueue.main.async {
            self.quakeTableViewController?.setRefreshEnabled(false)
        }

        let magnitude = shouldUseMinimumMagnitude ? minimumMagnitude : nil
        let startDate = Date(timeIntervalSinceNow: -historicalRange)

        earthquakeService.getEarthquakes(
            startDate: startDate,
            minMagnitude: magnitude
        ) { result in

            self.handleRefreshResult(result)
        }
    }

    private func handleRefreshResult(
        _ result: Result<FeatureCollection, EarthquakeServiceError>
    ) {
        // There will be UI updates, so come back to the main thread now.
        DispatchQueue.main.async {

            // We can untoggle the flag. This doesn't need a critical section
            // because it's a single operation.
            self.isNetworkActive = false
            self.quakeTableViewController?.setRefreshEnabled(true)

            switch result {

            // The network request succeeded.
            case .success(let collection):
                self.featureStore.load(collection.features)
                self.quakeTableViewController?.quakeListDidUpdate()


            // The network request failed.
            case .failure(let error):
                // Dropping the errors here, ideally would communicate
                // them through the UI.
                print("😱 network failure: \(error)")
            }
        }
    }

}
