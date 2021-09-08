//
//  QuakeSummaryTableViewCell.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import UIKit

// MARK: - Quake Summary Table View Cell

class QuakeSummaryTableViewCell: UITableViewCell {

    @IBOutlet weak var interiorView: UIView!
    @IBOutlet weak var magnitudeBox: UIView!
    @IBOutlet weak var magnitudeLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var coordsLabel: UILabel!
    @IBOutlet weak var agoLabel: UILabel!

    weak var coordinator: QuakeCoordinator?
    var feature: Feature?

}

// MARK: - Configuration

extension QuakeSummaryTableViewCell {

    func configure(feature: Feature?) {
        self.feature = feature

        interiorView.layer.cornerRadius = 3.0
        interiorView.layer.borderWidth = 2.0

        // We can use colours defined in the asset catalog to help to
        // maintain a cohesive design, and support dark mode. These
        // are mostly used in the storyboard but they're not as
        // obvious there.
        interiorView.layer.borderColor = UIColor(
            named: "BorderColour"
        )?.cgColor

        // Configure the magnitude box.
        configureMagnitude(feature: feature)

        // Configure the elapsed time label.
        if let dateDescription = feature?.elapsedDescription {
            agoLabel.text = dateDescription
        } else {
            agoLabel.text = "–"
        }

        // Configure the location title.
        if let location = feature?.properties.place?.capitalized {
            locationLabel.text = location
        } else {
            locationLabel.text = "–"
        }

        // Configure the type byline.
        configureTypeLine(feature: feature)

        // Configure event coordinates.
        if let coordDescription = feature?.coordinateDescription {
            coordsLabel.text = coordDescription
        } else {
            coordsLabel.text = "No Coords"
        }
    }

    func configureMagnitude(feature: Feature?) {
        magnitudeBox.layer.cornerRadius = 3.0
        magnitudeBox.layer.borderWidth = 2.0
        magnitudeBox.layer.borderColor = UIColor(
            named: "BorderColour"
        )?.cgColor

        guard
            let mag = feature?.properties.mag,
            let severity = feature?.severity
        else {
            magnitudeLabel.text = "–"
            magnitudeBox.backgroundColor = .white
            return
        }

        magnitudeLabel.text = "\(mag.to1dp)"

        switch severity {
        case .minor: magnitudeBox.backgroundColor = .lightGray
        case .moderate: magnitudeBox.backgroundColor = .yellow
        case .large: magnitudeBox.backgroundColor = .red
        }
    }

    func configureTypeLine(feature: Feature?) {
        guard var typeString = feature?.properties.type?.capitalized else {
            typeLabel.text = "Unknown event type"
            return
        }

        if let depth = feature?.depth {
            typeString += " at depth \(depth.to2dp) km"
        }

        typeLabel.text = typeString
    }

}
