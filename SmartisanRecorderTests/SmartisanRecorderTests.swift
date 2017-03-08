//
//  SmartisanRecorderTests.swift
//  SmartisanRecorderTests
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import XCTest
@testable import SmartisanRecorder

class SMRecorderTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSoundQuality() {
        let qulitysSet: Set = [SMRecorder.QualitySettings.high,
                               SMRecorder.QualitySettings.medium,
                               SMRecorder.QualitySettings.low]
        for quality in qulitysSet {
            SMRecorder.soundQuality = quality
            XCTAssertEqual(quality, SMRecorder.soundQuality, "Sound quality test false")
        }
    }
    
    func testDefaultFileName() {
        let homeDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let testPath = homeDirectory! + SMRecorder().defaultFileName
        XCTAssertFalse(FileManager.default.fileExists(atPath: testPath), "Default record file name is duplicated")
    }
    
    func testSave() {
        let recorder1 = SMRecorder()
        XCTAssertTrue(recorder1.record())
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let result = recorder1.save(with: recorder1.defaultFileName, complete: { (result) in
                XCTAssertTrue(result)
            })
            XCTAssertTrue(result)
        }
        
        let recorder2 = SMRecorder()
        XCTAssertTrue(recorder2.record())
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let result = recorder2.save(with: "Rec_001", complete: { (result) in
                XCTAssertTrue(true)
            })
            XCTAssertFalse(result)
        }
        
        let recorder3 = SMRecorder()
        XCTAssertTrue(recorder3.record())
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let result = recorder3.save(with: "\(arc4random() % 1000000)", complete: { (result) in
                XCTAssertTrue(result)
            })
            XCTAssertTrue(result)
        }
        
        let recorder4 = SMRecorder()
        XCTAssertTrue(recorder4.record())
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let result = recorder4.save(with: "", complete: { (result) in
                XCTAssertTrue(true)
            })
            XCTAssertFalse(result)
        }
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}

class SMAudioToolsTest: XCTestCase {
    func testLinearLevel() {
        for _ in 0..<10 {
            let resultRange =  Float(arc4random() % 640)
            let audioMeter = SMAudioMeter(resultRange: resultRange)
            for _ in 0..<100 {
                let linearLevel = audioMeter.linearLevel(with: -Float(arc4random() % 160))
                XCTAssertLessThanOrEqual(linearLevel, resultRange)
                XCTAssertGreaterThanOrEqual(linearLevel, 0)
            }
        }
    }
}
