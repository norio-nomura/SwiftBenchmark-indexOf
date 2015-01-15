//
//  Benchmark.swift
//  Benchmark
//
//  Created by 野村 憲男 on 2015/01/14.
//
//

import Foundation
import XCTest

let kNumberOfElements = 100000
let kNumberOfValues = 10

class Benchmark: XCTestCase {
    struct Static {
        static let elements = map(randomNumbersFrom(1...kNumberOfElements, count: kNumberOfElements), {$0})
        static let values = map(randomNumbersFrom(1...kNumberOfElements, count: kNumberOfValues), {Static.elements[$0]})
    }
    var elements: [Int] {
        return Static.elements
    }
    var values: [Int] {
        return Static.values
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformance_v1() {
        self.measureBlock() {
            var results = self.values.map { value -> Int? in
                v1_index_of(self.elements, {$0 == value})
            }
            println("results: \(results)")
        }
    }
    func testPerformance_v2() {
        self.measureBlock() {
            var results = self.values.map { value -> Int? in
                v2_index_of(self.elements, {$0 == value})
            }
            println("results: \(results)")
        }
    }
    func testPerformance_v2_1() {
        self.measureBlock() {
            var results = self.values.map { value -> Int? in
                v2_1_index_of(self.elements, {$0 == value})
            }
            println("results: \(results)")
        }
    }
    func testPerformance_v3() {
        self.measureBlock() {
            var results = self.values.map { value -> Int? in
                v3_index_of(self.elements, {$0 == value})
            }
            println("results: \(results)")
        }
    }
    func testPerformance_v4() {
        self.measureBlock() {
            var results = self.values.map { value -> Int? in
                self.elements.indexOf {$0 == value}
            }
            println("results: \(results)")
        }
    }
}
