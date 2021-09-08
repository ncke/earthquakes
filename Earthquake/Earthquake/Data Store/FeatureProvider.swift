//
//  FeatureProvider.swift
//  Earthquake
//
//  Created by Nick on 08/09/2021.
//

import Foundation

// A protocol can be used here to abstract the storage concept away from the
// underlying storage mechanism. The advantage is increased flexibility in
// selecting and maintaining the actual store. The actual store could use
// e.g. Core Data, Realm, it could have caching, or data could be
// composed from several underlying stores (in more complex designs).

protocol FeatureProvider {

    /// Returns the number of features available.
    var featureCount: Int { get }

    /// Returns the indexed feature, or nil if the index is outside
    /// of the range.
    func feature(forIndex index: Int) -> Feature?

}

// A protocol extension can be used as an adapter. Here we are enabling
// a Quake Data Store (which is a generic type) to act as a Feature
// Provider when it is being used to store features. In this case it's a
// simple mapping, so probably overkill.

extension QuakeDataStore: FeatureProvider where Item: Feature {

    var featureCount: Int { count }

    func feature(forIndex index: Int) -> Feature? { self[index] }

}
