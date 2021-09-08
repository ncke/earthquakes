//
//  EarthquakeService.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import Foundation

// MARK: - Earthquake Service Completion

typealias EarthquakeServiceCompletion = (
    Result<FeatureCollection, EarthquakeServiceError>
) -> Void

// MARK: - Earthquake Service

struct EarthquakeService {

    // Nb: The @escaping annotation denotes that the closure will be retained
    // after the function has returned (in this case it is captured by the
    // data task's completion block).

    // For larger interfaces, we can provide more documentation inline
    // with the code by using multi-line documentation comments.

    /**
     Queries the USGS earthquake service for a collection of events.

     - Parameter startDate: The date from which to start the collection.
     - Parameter minMagnitude: The minimum seismic magnitude for inclusion
     in the collection, if you pass nil then all available events are
     included.
     - Parameter completion: A function to call to handle the result once
     the query has finished. The function must accept a single parameter
     which is a Result type that holds the received FeatureCollection in
     the event of success, or an error in the event of failure.
     */
    func getEarthquakes(
        startDate: Date,
        minMagnitude: Double? = nil,
        completion: @escaping EarthquakeServiceCompletion
    ) {

        guard let url = url(
                startDate: startDate,
                minMagnitude: minMagnitude
        ) else {
            // We could not make the URL. The choice here is to use the
            // completion handler to communicate this error. An alternative
            // would be to throw the error directly because we're not
            // async yet so we still have the call stack available to
            // propagate the error. Using the completion handler for this may
            // surprise the caller and there could be nuances if the
            // caller has assumed that the completion handler will definitely
            // be called only after the function has returned. But the
            // type safety on the getEarthquakes function signature makes
            // this eventuality more of an implementation error (e.g. malformed
            // base URL) so perhaps even fatal error would be justifiable.
            // Given the above, this simplifies the call site.
            completion(.failure(EarthquakeServiceError.badParameters))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                // Networking failed on the local device.
                let serviceError = EarthquakeServiceError.networkFailed(
                    underlyingError: error
                )

                completion(.failure(serviceError))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !isSuccessStatusCode(httpResponse.statusCode)
            {
                // The HTTP response code indicates failure.
                let serviceError = EarthquakeServiceError.requestFailed(
                    statusCode: httpResponse.statusCode
                )

                completion(.failure(serviceError))
                return
            }

            guard let data = data, !data.isEmpty else {
                // The request succeeded, but no data was returned.
                completion(.failure(EarthquakeServiceError.missingData))
                return
            }

            guard let collection: FeatureCollection = decode(data: data) else {
                // The data could not be decoded as a feature collection
                // (list of earthquakes).
                completion(.failure(EarthquakeServiceError.decodingFailed))
                return
            }

            // We got the list of earthquakes!
            completion(.success(collection))

        }.resume()
    }

}

// MARK: - Helpers

private extension EarthquakeService {

    /// A chatty decoder to catch JSON parsing errors.
    func decode<T: Decodable>(data: Data) -> T? {
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded

        } catch {
            print("😱 decoding error \(error)")
            return nil

        }
    }

    /// Returns true if the HTTP status code represents a success.
    func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        // This is quite a broad brush and we've chosen not to handle
        // redirection.
        (200...299).contains(statusCode)
    }

}

// MARK: - Resolve URL for Query

private extension EarthquakeService {

    /// The base URL for queries to the USGS earthquake service.
    static let baseUrl: URL = {
        URL(string: "https://earthquake.usgs.gov/fdsnws/event/1/query")!
    }()

    /// Formulates a query URL with the given query parameters.
    func url(startDate: Date, minMagnitude: Double?) -> URL? {
        var queryItems = [
            URLQueryItem(name: "format", value: "geojson"),
            URLQueryItem(name: "starttime", value: iso8601(date: startDate))
        ]

        if let mag = minMagnitude {
            let item = URLQueryItem(name: "minmagnitude", value: String(mag))
            queryItems.append(item)
        }

        guard var urlComponents = URLComponents(
                url: EarthquakeService.baseUrl,
                resolvingAgainstBaseURL: true
        ) else {
            return nil
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
    }

}

// MARK: - ISO 8601 Date Conversion

private extension EarthquakeService {

    static let iso8601DateFormatter = ISO8601DateFormatter()

    /// Returns a string representing the given date in ISO 8601 format.
    func iso8601(date: Date) -> String {
        EarthquakeService.iso8601DateFormatter.string(from: date)
    }

}

// MARK: - Errors

enum EarthquakeServiceError: Error {

    /// The parameters could not be used to form a valid query URL.
    case badParameters

    /// Networking failed locally (e.g. timeout, connectivity).
    case networkFailed(underlyingError: Error)

    /// The remote host responded with a failing status code.
    case requestFailed(statusCode: Int)

    /// The response did not contain data.
    case missingData

    /// The data in the response could not be decoded.
    case decodingFailed
}
