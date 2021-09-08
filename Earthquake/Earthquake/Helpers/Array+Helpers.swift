//
//  Array+Helpers.swift
//  Earthquake
//
//  Created by Nick on 08/09/2021.
//

import Foundation

extension Array {

    /// Returns the first instance of a subtype, nil if none found.
    func firstAmong<T>() -> T? { self.first { element in element is T } as? T }

}
