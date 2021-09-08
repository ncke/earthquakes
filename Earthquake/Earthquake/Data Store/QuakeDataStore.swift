//
//  QuakeDataStore.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import Foundation

/// Provides a generic random-access in-memory data store for use within
/// the application.
class QuakeDataStore<Item> {

    private var items = [Item]()
    private var lock = NSLock()

    /// Return the store item at the given index, nil if the index
    /// is out of range.
    subscript(_ index: Int) -> Item? {
        lock.lock()
        defer { lock.unlock() }

        guard index >= 0 && index < items.count else {
            return nil
        }

        return items[index]
    }

    /// Returns the number of items in the store.
    var count: Int {
        lock.lock()
        defer { lock.unlock() }

        return items.count
    }

    /// Loads the store with items.
    func load(_ items: [Item]) {
        lock.lock()
        defer { lock.unlock() }

        self.items = items
    }

    /// Removes all items from the store.
    func clear() {
        lock.lock()
        defer { lock.unlock() }

        items = []
    }

}
