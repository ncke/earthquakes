//
//  Feature.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import Foundation

// MARK: - Feature Collection

/// A collection of seismic event features.
class FeatureCollection: Codable {

    let features: [Feature]

}

// MARK: - Feature

/// A seismic event feature.
class Feature: Codable {

    // The basic set of Feature instance properties is initialised from a
    // JSON representation by the EarthquakeService when data from the
    // network is decoded.

    class Properties: Codable {
        let mag: Double?
        let place: String?
        let time: TimeInterval?
        let type: String?
        let title: String?
    }

    class Geometry: Codable {
        let type: String?
        let coordinates: [Double]?
    }

    let identifier: String
    let properties: Properties
    let geometry: Geometry

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case properties = "properties"
        case geometry = "geometry"
    }

}

// We can use class extensions to provide additional computed properties.
// Many callsites will have similar requirements so, as long as we stick
// to the remit of a business object (and not UI), we can cater for
// that here.

// MARK: - Severity Categorisation

// For example, severity is used to drive the colour coding of magnitudes
// on the summary cell. Adding severity to the Feature model means that the
// idea of severity can be shared throughout the app. It wouldn't be
// appropriate for the Feature to provide the actual colours though as that's
// in the UI domain.

extension Feature {
    private static let moderateBoundary = 3.0
    private static let largeBoundary = 5.0

    enum Severity {
        case minor, moderate, large
    }

    /// Returns the severity of the event, if known.
    var severity: Severity? {
        guard let mag = self.properties.mag else {
            return nil
        }

        if mag < Feature.moderateBoundary {
            return .minor
        } else if mag < Feature.largeBoundary {
            return .moderate
        } else {
            return .large
        }
    }

}

// MARK: - Location and Depth

extension Feature {

    /// Returns a tuple containing the latitude and longitude coordinates
    /// of the event, if known.
    var latlong: (Double, Double)? {
        guard let coords = pointCoords(), coords.count >= 2 else {
            return nil
        }

        return (coords[1], coords[0])
    }

    /// Returns the depth of the event in kilometres, if known.
    var depth: Double? {
        guard let coords = pointCoords(), coords.count >= 3 else {
            return nil
        }

        return coords[2]
    }

    private func pointCoords() -> [Double]? {
        guard geometry.type == "Point", let coords = geometry.coordinates else {
            return nil
        }

        return coords
    }

    /// Returns a string that describes the coordinates of the event
    /// in a human readable form, nil if the coordinates are unknown.
    var coordinateDescription: String? {
        guard let (lat, lon) = latlong else {
            return nil
        }

        let latString = lat < 0 ? "\(-lat.to2dp)°E" : "\(lat.to2dp)°W"
        let lonString = lon < 0 ? "\(-lon.to2dp)°S" : "\(lon.to2dp)°N"
        return latString + " " + lonString
    }

}

// MARK: - Event Date

// The USGS service records time as milliseconds since 1970, we provide
// some helpers to make that more amenable.

extension Feature {
    private static let oneMinute: TimeInterval = 60
    private static let fiveMinutes: TimeInterval = 5 * 60
    private static let oneHour: TimeInterval = 60 * 60
    private static let halfDay: TimeInterval = 12 * 60 * 60

    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE, HH:mm"
        return df
    }()

    /// The date on which the event occurred, if known.
    var eventDate: Date? {
        guard let eventMillis = properties.time else {
            return nil
        }

        return Date(timeIntervalSince1970: eventMillis / 1000.0)
    }

    /// A human readable description of the event date, if known.
    var dateDescription: String? {
        guard let eventDate = eventDate else {
            return nil
        }

        return Feature.dayFormatter.string(from: eventDate)
    }

    /// The number of seconds that have elapsed since the event, if known.
    var elapsedTime: TimeInterval? {
        guard let eventDate = eventDate else {
            return nil
        }

        return -eventDate.timeIntervalSinceNow
    }

    /// A human readable description of the elapsed time since the event,
    /// if known.
    var elapsedDescription: String? {
        guard let elapsedTime = elapsedTime else {
            return nil
        }

        /// Handle truncation and pluralisation of the unit.
        func format(_ value: Double, unit: String) -> String {
            let intValue = Int(value)
            let formattedValue = String(intValue)
            let formattedUnit = intValue == 1 ? unit : unit + "s"

            return formattedValue + " " + formattedUnit + " Ago"
        }

        if elapsedTime < Feature.fiveMinutes {
            return "Now"
        } else if elapsedTime < Feature.oneHour {
            return format(elapsedTime / Feature.oneMinute, unit: "Minute")
        } else if elapsedTime < Feature.halfDay {
            return format(elapsedTime / Feature.oneHour, unit: "Hour")
        }

        guard let eventDate = eventDate else { return nil }

        let dayString = Feature.dayFormatter.string(from: eventDate)
        return dayString
    }

}
