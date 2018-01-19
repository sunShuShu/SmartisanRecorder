//
//  ToolTests.swift
//  SmartisanRecorderTests
//
//  Created by sunda on 29/08/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import XCTest
@testable import SmartisanRecorder

class SMToolTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLog() {
        SMLog("I'm a low level log.")
        SMLog("I'm a low level log.")
        SMLog("I'm a medium level log!", level: .medium)
        SMLog("I'm a medium level log!", level: .medium)
        SMLog("I'm a high level log!!", level: .high)
        SMLog("I'm a high level log!!", level: .high)
    }
    
    func testArrayBinarySearch() {
        var testArray = [SMTime]()
        for index in 0..<99 {
            testArray.append(SMTime(index * 10))
        }
        
        var subArray = testArray.binarySearch(from: 200, to: 200)
        XCTAssert(subArray?.count == 1 && subArray?.first == 200)

        subArray = testArray.binarySearch(from: 100, to: 500)
        XCTAssert(subArray?.count == 41)

        subArray = testArray.binarySearch(from: 255, to: 705)
        XCTAssert(subArray?.count == 45)

        subArray = testArray.binarySearch(from: 405, to: 405)
        XCTAssert(subArray == nil)

        subArray = testArray.binarySearch(from: -100, to: -50)
        XCTAssert(subArray == nil)

        subArray = testArray.binarySearch(from: -100, to: 455)
        XCTAssert(subArray?.count == 47)

        subArray = testArray.binarySearch(from: 805, to: 815)
        XCTAssert(subArray?.count == 1 && subArray?.first == 810)
    }
}
