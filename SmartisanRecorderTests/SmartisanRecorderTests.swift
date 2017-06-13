//
//  SmartisanRecorderTests.swift
//  SmartisanRecorderTests
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import XCTest
@testable import SmartisanRecorder
import AVFoundation

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
    
    func testInterpolate() {
        let testDataLength = 1024 * 1024 * 10
        let testTimes = 6
        let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: testDataLength);
        for index: Int in 0..<testDataLength {
            inputBuffer[index] = UInt8(index)
        }
        
        var output: UnsafeMutablePointer<UInt8>?
        self.measure {
            output = SMResample.interpolate(testTimes, buffer: inputBuffer, length: testDataLength)
        }
        
    }
    
    func testPCMMerge() {
        self.measure {
            let exp = self.expectation(description: "Audio file editor")
            let outURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/merge\(arc4random() % 9999).wav")
            
            let url1 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "1 Merge_高_中", ofType: "wav")!)
            let url2 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "低", ofType: "wav")!)
            let editor = SMAudioFileEditor(inputURLs: [url1, url2], outputURL: outURL) { (result, error) in
                XCTAssertTrue(result)
                print(error ?? "Merge success")
                exp.fulfill()
            }
            
            XCTAssertNotNil(editor)
            editor!.merge()
            
            self.waitForExpectations(timeout: 600) { (error) in
                XCTAssertTrue(true)
            }
        }
    }
    
}
