//
//  QuakeDataStore.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import Foundation

class QuakeDataStore<Item> {

    private var items = [Item]()
    private var lock = NSLock()

    subscript(_ index: Int) -> Item? {
        lock.lock()
        defer { lock.unlock() }

        guard index >= 0 && index < items.count else {
            return nil
        }

        return items[index]
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }

        return items.count
    }

    func load(_ items: [Item]) {
        lock.lock()
        defer { lock.unlock() }

        self.items = items
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }

        items = []
    }

}
