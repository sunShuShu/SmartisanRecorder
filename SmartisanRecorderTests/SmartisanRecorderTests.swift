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
            self.waitForExpectations(timeout: 60) { (error) in
                XCTAssertTrue(true)
            }
        }
    }
}

class SMAudioFileEditorTest: XCTestCase {
//    func testMerge() {
//        let exp = self.expectation(description: "Audio file editor")
//        self.measure {
//            let path1 = Bundle(for: type(of: self)).path(forResource: "drums", ofType: "wav")
//            let path2 = Bundle(for: type(of: self)).path(forResource: "guitar", ofType: "wav")
//            let outPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/merge\(arc4random() % 9999).wav"
//            let resutlt = SMAudioFileEditor.mergeWAVE(inputURLs: [URL(fileURLWithPath: path1!),
//                                                        URL(fileURLWithPath: path2!)], outputURL: URL(fileURLWithPath: outPath))
//            XCTAssertTrue(resutlt)
//            exp.fulfill()
//        }
//        waitForExpectations(timeout: 9999) { (error) in
//            XCTAssertTrue(true)
//        }
//    }
    
    func testPCMMerge() {
        self.measure {
            let exp = self.expectation(description: "Audio file editor")
            let outRUL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/merge\(arc4random() % 9999).wav")
            
            let url1 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "1 Merge_高_中", ofType: "wav")!)
            let url2 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "1 Merge_高_中", ofType: "wav")!)
            let editor = SMAudioFileEditor(inputURLs: [url1, url2], outputURL: outRUL) { (result, error) in
                XCTAssertTrue(result)
                print(error ?? "Merge success")
                exp.fulfill()
            }
            XCTAssertNotNil(editor)
            editor!.merge()
            
            self.waitForExpectations(timeout: 60) { (error) in
                XCTAssertTrue(true)
            }
        }
    }
}
