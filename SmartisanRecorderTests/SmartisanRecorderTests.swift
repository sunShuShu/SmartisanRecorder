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

class SMAudioFileSamplerTest: XCTestCase {
    func testSimple() {
        self.measure {
            let exp = self.expectation(description: "Audio file sample")
            let path = Bundle(for: type(of: self)).path(forResource: "guitar", ofType: "wav")
            SMAudioFileSampler.sample(url: URL(fileURLWithPath: path!), countPerSecond: 50, completion: { (sampleData) in
                XCTAssertNotNil(sampleData)
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 60) { (error) in
            XCTAssertTrue(true)
        }
    }
}
