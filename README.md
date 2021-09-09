# earthquakes
An iOS demo app to show current earthquake activity.

Some screenshots from the app are included below.

| Quake List & Filters | Quake Detail | Dark Mode |
|------------|------------|------------|
|![image](https://github.com/ncke/earthquakes/blob/36ed497734f67798f7f8f91e1eda9b11aae46f2d/Other/fig-1.png)|![image](https://github.com/ncke/earthquakes/blob/36ed497734f67798f7f8f91e1eda9b11aae46f2d/Other/fig-2.png)|![image](https://github.com/ncke/earthquakes/blob/36ed497734f67798f7f8f91e1eda9b11aae46f2d/Other/fig-3.png)|

## API
The app uses the public USGS earthquake event service. More information about the API is here [https://earthquake.usgs.gov/fdsnws/event/1/].

## Toolchain
Xcode 12.5.1 and Swift 5. The app adopts a minimum deployment target of iOS 13.6.

## Approach
This is a simple MVVM-C implementation.

There are two view controllers:

* `QuakeSettingsTableViewController` presents the user with a list of the latest earthquakes (and some other events tracked by the USGS), once these have been obtained from the API service. The first cell in the table view provides the user with filter settings to adjust the search (the user needs to explicitly tap to refresh once the settings have been configured). The filter is a `QuakeSettingsTableViewCell` and the summary list cells are `QuakeSummaryTableViewCell`.

* `QuakeDetailViewController` presents the user with more detailed information about the earthquake in response to a tap on a summary cell. This includes a map of the location involved.

Other anatomy:

* `QuakeCoordinator` is the coordinator instance. Once active it takes charge of presenting and dismissing view controllers such as the Detail View Controller. It offers various methods for other components in the app to use when requesting actions. It coordinates between the data store, networking, and user interface (such as letting UI know to disable refresh affordances when networking is ongoing). This app has a single coordinator, but often there are child coordinators created for the duration of some particular user flow. In this case the single coordinator is in place throughout the app session.

* `QuakeNavController` is used by the coordinator to manage the view hierarchy. In this demo, the nav controller is instantiated from the storyboard automatically as an initial view controller. So, for convenience really, it creates and holds the coordinator because it lives throughout the app life cycle in this case.

* `EarthquakeService` is responsible for managing calls to the USGS public API. This includes translating the filter parameters to a URL for the request. The USGS terms events in its list as 'features'. A successful service call returns a `FeatureCollection` that contains an array of `Feature` instances.

* `Feature` is a model object that represents an earthquake event. It maps from the service's JSON data using a Codable conformance, but it also has an (unnecessary) example of using coding keys to rename a property. More usefully, the model has several class extensions that offer readable event dates, locations and a severity enum.

* `QuakeDataStore` is a data store that can store a generic type. This makes it easily testable and there's a test class in `QuakeDataStoreTests` to demonstrate this using Ints. In the app it is used to store `Feature` items.

* `FeatureProvider` is an example of a protocol used to abstract access to feature data away from the underlying technology that is providing it. There's also a protocol extension that conforms `QuakeDataStore` to the `FeatureProvider` protocol subject to it having the corresponding generic type.

## Other things

I've commented in the code _a lot_ more than I normally would, just for exposition.

Testing: More unit tests could be added, time ran short. UITests can also be added, and a CI pipeline established.

Design: The app supports light and dark mode using named colours in an Asset Catalog. Layout is optimised for the test device which was an iPhone 12 Pro Max simulator running iOS 14.5. The app supports devices with other size classes (e.g. iPad) and device orientations (e.g. landscape), but the horizontal extent of the table view in some cases leaves space unused. Moving to cards in a UICollectionView would be an approach to this.
