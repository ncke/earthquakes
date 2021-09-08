//
//  QuakeDataStoreTests.swift
//  EarthquakeTests
//
//  Created by Nick on 08/09/2021.
//

import XCTest
@testable import Earthquake

class QuakeDataStoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetup() {
        let sut = QuakeDataStore<Int>()

        // An empty data store is initialised.
        XCTAssertEqual(sut.count, 0)
    }

    func testLoad() {
        let sut = QuakeDataStore<Int>()

        XCTAssertEqual(sut.count, 0)
        sut.load([1, 2, 3, 4])
        XCTAssertEqual(sut.count, 4)
    }

    func testFetch() {
        let sut = QuakeDataStore<Int>()
        sut.load([1, 2, 3, 4])

        XCTAssertEqual(sut[0], 1)
        XCTAssertEqual(sut[1], 2)
        XCTAssertEqual(sut[2], 3)
        XCTAssertEqual(sut[3], 4)

        XCTAssertNil(sut[-2])
        XCTAssertNil(sut[23])
    }

    func testClear() {
        let sut = QuakeDataStore<Int>()
        sut.load([1, 2, 3, 4])

        XCTAssertEqual(sut.count, 4)
        sut.clear()
        XCTAssertEqual(sut.count, 0)
    }

    func testLoadPerformance() throws {
        let sut = QuakeDataStore<Int>()
        let items = [Int](repeating: 0, count: 10000)

        self.measure {
            sut.load(items)
        }
    }

    func testFetchPerformance() throws {
        let sut = QuakeDataStore<Int>()
        let items = [Int](repeating: 0, count: 10000)
        sut.load(items)
        XCTAssertEqual(sut.count, 10000)

        self.measure {
            guard let index = (0..<10000).randomElement() else {
                XCTFail()
                fatalError()
            }

            _ = sut[index]
        }
    }

}
