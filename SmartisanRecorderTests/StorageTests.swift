//
//  StorageTests.swift
//  SmartisanRecorderTests
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import XCTest
@testable import SmartisanRecorder

class SMStorageTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTable() {
        let url = URL.init(string: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! + "/test.db")
        let table = "table_\(arc4random() % 999)";
        let storage = SMStorage.init(databasePath: url)
        XCTAssertNotNil(storage)
        let createResult = storage!.createTable(table, class: SMFileStorageModel.self)
        XCTAssert(createResult)
        storage
        storage?.dropTable(table)
    }
    
}