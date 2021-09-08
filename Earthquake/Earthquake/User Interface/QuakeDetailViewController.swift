//
//  QuakeDetailViewController.swift
//  Earthquake
//
//  Created by Nick on 08/09/2021.
//

import MapKit
import UIKit

// MARK: - Quake Detail View Controller

class QuakeDetailViewController: UIViewController {

    @IBOutlet weak var mapKitView: MKMapView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var coordLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var magLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!

    weak var coordinator: QuakeCoordinator?
    var feature: Feature?

}

// MARK: - Configuration

extension QuakeDetailViewController {

    func configure(feature: Feature?) {
        // We keep the feature and complete the configuration of the
        // UI when the view is about to appear. The view furniture is
        // loaded lazily by UIKit, so it's not immediately available.
        self.feature = feature
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.titleLabel.text = feature?.properties.title ?? "USGS Feature"

        self.identifierLabel.text = feature?.identifier ?? "–"

        self.dateLabel.text = feature?.dateDescription ?? "–"

        self.coordLabel.text = feature?.coordinateDescription ?? "–"

        self.typeLabel.text = feature?.properties.type?.capitalized ?? "–"

        if let mag = feature?.properties.mag {
            self.magLabel.text = "M \(mag.to2dp)"
        } else {
            self.magLabel.text = "–"
        }

        if let depth = feature?.depth {
            self.depthLabel.text = "\(depth.to2dp) km"
        } else {
            self.depthLabel.text = "–"
        }

        if let (lat, lon) = feature?.latlong {
            configureMap(lat: lat, lon: lon)
        }

    }

    /// Drive the map to the event location.
    private func configureMap(lat: Double, lon: Double) {
        var location = CLLocationCoordinate2DMake(lat, lon)
        var span = MKCoordinateSpan(latitudeDelta: 7.0, longitudeDelta: 7.0)
        var isValid = true

        if !CLLocationCoordinate2DIsValid(location) {
            // We could not get a valid location, so show that spot in
            // the Atlantic.
            isValid = false
            location = CLLocationCoordinate2DMake(0, 0)
            span = MKCoordinateSpan(latitudeDelta: 80.0, longitudeDelta: 80.0)
        }

        let region = MKCoordinateRegion(center: location, span: span)
        mapKitView.setRegion(region, animated: true)

        // Add a pin to a valid location.
        if isValid {
            let pin = MKPointAnnotation()
            pin.coordinate = location

            mapKitView.addAnnotation(pin)
        }
    }

}
