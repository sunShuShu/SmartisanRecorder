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
    
}
