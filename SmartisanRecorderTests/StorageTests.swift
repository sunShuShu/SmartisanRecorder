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
    
    let optionTimes = 5
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDatabase() {
        objc_sync_enter(self)
        let filePath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! + "/test.db"
        let url = URL.init(fileURLWithPath: filePath)
        print(url.absoluteString as Any)
        var storage = SMStorage.init(databasePath: filePath,
                                     table: "SMAudioFile",
                                     class: SMFileStorageModel.self,
                                     errorBlock: { error in
                                        XCTAssert(false, "\(error)")
        })
        XCTAssertNotNil(storage)

        var allModel = [SMFileStorageModel]()
        for _ in 0..<optionTimes {
            let model = SMFileStorageModel();
            model.name = "Rec_录音_\(arc4random() % 9999)"
            model.voiceType = SMVoiceTypePhontCall
            model.md5 = "fhdjsklafh436543dsjkalfjdsafdsa5555fdhsg5555"
            model.pointCount = 5
            model.pointFileName = "I am point file name"
            model.waveformFileName = "Waveform File Name"
            let insertResult = storage?.insert(model)
            XCTAssert(model.localID != 0)
            XCTAssertNotNil(insertResult)
            allModel.append(model)
        }
        
        var allObjects = storage?.getAllObjects()
        XCTAssert(allObjects?.count == optionTimes)
        
        let model = SMFileStorageModel();
        model.name = "Rec_录音_test_update"
        model.voiceType = SMVoiceTypePhontCall
        model.md5 = "fhdjsklafh436543dsjkalfjdsafdsa5555fdhsg5555"
        model.pointCount = 5
        model.pointFileName = "I am point file name"
        model.waveformFileName = "Waveform File Name"
        model.setValue(1, forKey: "localID")
        let updateResult = storage?.update(model)
        XCTAssertNotNil(updateResult)
        
        let deleteResult = storage?.deleteObject(1)
        XCTAssertNotNil(deleteResult)
        allObjects = storage?.getAllObjects()
        XCTAssert(allObjects?.count == optionTimes - 1)
        storage = nil
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch  {
            XCTAssert(false, error.localizedDescription)
        }
        objc_sync_exit(self)
    }
}
