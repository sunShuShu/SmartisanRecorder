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
            model.fileSize = 4*1024*1024*1024
            model.createTime = Date()
            model.pointCount = 5
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
        model.fileSize = 4*1024*1024*1024
        model.createTime = Date()
        model.pointCount = 5
        model.setValue(1, forKey: "localID")
        let updateResult = storage?.modifyObject(model)
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
    
    func testFileInfoStorag() {
        let storage = SMFileInfoStorage()
        XCTAssertNotNil(storage)
        
        var allModel = [SMFileStorageModel]()
        for _ in 0..<optionTimes {
            let model = SMFileStorageModel();
            let filePath = Bundle.main.path(forResource: "1 Merge_高_中", ofType: "wav")
            model.name = "Rec_录音_\(arc4random() % 9999).wav"
            model.voiceType = SMVoiceTypePhontCall
            model.fileSize = 2319400
            model.createTime = Date()
            model.pointCount = 5
            let insertResult = storage!.addFile(model)
            XCTAssertTrue(insertResult)
            let data = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
            let fakeFile = FileManager.default.createFile(atPath: "\(SMRecorder.filePath)/\(model.name)", contents: data, attributes: nil)
            XCTAssertTrue(fakeFile)
            allModel.append(model)
        }
        
        let files = storage?.getAllFiles()
        XCTAssert(files?.count == allModel.count)
        
        for model in allModel {
            do {
                try FileManager.default.removeItem(atPath: "\(SMRecorder.filePath)/\(model.name)")
            } catch  {
                XCTAssert(false, "\(error)")
            }
        }
        do {
            try FileManager.default.removeItem(atPath: "\(SMFileInfoStorage.filePath)/SMAudioFile.db")
        } catch  {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testAudioInfo() {
        var storage: SMAudioInfoStorage? = SMAudioInfoStorage(audioFileName: "test.wav")
        var fakeWaveformArray = [UInt8]()
        var fakePointsArray = [UInt32]()
        for _ in 0..<1080 {
            let fakeValue = UInt8(arc4random() % 255)
            storage!.waveform.append(fakeValue)
            fakeWaveformArray.append(fakeValue)
        }
        for _ in 0..<100 {
            let fakeValue = UInt32(arc4random() % (72*3600*50))
            storage!.pointLocation.append(fakeValue)
            fakePointsArray.append(fakeValue)
        }
        storage = nil
        
        var storage2: SMAudioInfoStorage? = SMAudioInfoStorage(audioFileName: "test.wav")
        XCTAssert(storage2!.waveform == fakeWaveformArray)
        XCTAssertTrue(storage2!.pointLocation == fakePointsArray)
        
        storage2!.waveform.remove(at: 1079)
        storage2!.waveform.remove(at: 3)
        fakeWaveformArray.remove(at: 1079)
        fakeWaveformArray.remove(at: 3)
        storage2!.saveEneireWaveform()
        storage2 = nil
        
        let storage3 = SMAudioInfoStorage(audioFileName: "test.wav")
        XCTAssertTrue(storage3.waveform == fakeWaveformArray)
        
        storage3.deleteFile()
    }
}
