//
//  QuakeTableViewController.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import UIKit

// MARK: - Quake Table View Controller

class QuakeTableViewController: UITableViewController {

    weak var coordinator: QuakeCoordinator?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set up a bar button item to allow the user to refresh.
        let item = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(tappedRefresh)
        )
        self.navigationItem.rightBarButtonItem = item
    }

    // Reference to a function through a selector requires that it is
    // available to the Obj-C runtime, but this is a UIKit subclass anyway.
    @objc func tappedRefresh() {
        coordinator?.refreshQuakeList()
    }

}

// MARK: - Coordinator Interface

// In more complex structures it can be helpful to abstract interfaces
// into protocols, perhaps a 'QuakeListPresenting' protocol. Just keeping
// it simple here.

extension QuakeTableViewController {

    /// Called by the coordinator to indicate that the list of quakes has
    /// been updated.
    func quakeListDidUpdate() {
        // The data store contents are entirely replaced by the new
        // download, so we reload the whole table. However, if there are
        // incremental changes, then we could begin and commit table
        // updates or use a fetched results controller.
        tableView.reloadData()
    }

    // Called by the coordinator to instruct whether the refresh
    // functionality should be available to the user, or not. We
    // don't want the user mashing refresh when we already have
    // network activity ongoing. Something like a spinner would
    // also be nice, but not implemented here.
    func setRefreshEnabled(_ enabled: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = enabled

        // We need to tell the filter cell to update its refresh button
        // too. The cell has a fixed index path. It's ok if the table view
        // doesn't have a filter cell at the moment, it will pick
        // up the change the next time it's dequeued and configured.
        let filterPath = IndexPath(row: 0, section: 0)
        if let filterCell = tableView.cellForRow(
                at: filterPath
            ) as? QuakeSettingsTableViewCell
        {
            filterCell.setRefreshEnabled(enabled)
        }
    }

}

// MARK: - TableView Delegate and Data Source

// As TableViewController subclass we already conform to the protocols,
// but we can group this functionality into a section for the purposes
// of code organisation.

extension QuakeTableViewController {
    private static let filterCellIdentifier = "SETTINGS-CELL"
    private static let summaryCellIdentifier = "SUMMARY-CELL"

    override func numberOfSections(in tableView: UITableView) -> Int {
        // The first section is used to contain the filter interface. The
        // second section has the list itself. We could use a single
        // section by '+1'ing the count, but having two sections makes that
        // more straightforward.
        return 2
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        switch section {

        // First section contains a single filter cell.
        case 0: return 1

        // The quakes.
        case 1: return coordinator?.featureCount ?? 0

        // Illegal section!
        default: fatalError()

        }
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch indexPath.section {

        // Seismic Filter Cell.
        case 0:
            // The prototype cells are registered automatically with the
            // table view so it recognises the identifier and produces a
            // cell of the correct type, but we still need to cast it so
            // we can access its functionality.
            let dequeuedCell = tableView.dequeueReusableCell(
                withIdentifier: QuakeTableViewController.filterCellIdentifier,
                for: indexPath
            ) as! QuakeSettingsTableViewCell

            // Set up the cell.
            dequeuedCell.coordinator = self.coordinator
            dequeuedCell.configure()

            return dequeuedCell

        // Summary Cell.
        case 1:
            let dequeuedCell = tableView.dequeueReusableCell(
                withIdentifier: QuakeTableViewController.summaryCellIdentifier,
                for: indexPath
            ) as! QuakeSummaryTableViewCell

            // Get the corresponding feature and configure.
            let feature = coordinator?.feature(forIndex: indexPath.row)
            dequeuedCell.coordinator = self.coordinator
            dequeuedCell.configure(feature: feature)

            return dequeuedCell

        default:
            fatalError() // Illegal section.
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // We are only interested in selection of quake events.
        guard indexPath.section == 1 else {
            return nil
        }

        coordinator?.userRequestsDetail(featureIndex: indexPath.row)

        return nil
    }

}
