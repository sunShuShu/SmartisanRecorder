//
//  SmartisanRecorderRecorderTests.swift
//  SmartisanRecorderTests
//
//  Created by sunda on 25/08/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import XCTest
@testable import SmartisanRecorder

class SMRecordTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRecord() {
//        waveformView.backgroundColor = UIColor.gray
//        waveformView.frame = CGRect(x: 0, y: 0, width: 1000, height: 300)
//        scrollView.addSubview(waveformView)
//        scrollView.contentSize = waveformView.bounds.size
//
//        recoder.record()
//        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerFire), userInfo: nil, repeats: true)
//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 10) {
//            self.recoder.save(with: "Rec_006", completion: { (result) in
//                print(result)
//            })
//        }
        
        //    @objc private func timerFire() {
        //        let db = recoder.powerLevel
        //        let amp = audioMeter.linearLevel(with: db)
        //        waveformView.powerLevel.append(CGFloat(amp))
        //        waveformView.powerLevel = waveformView.powerLevel
        //
        //        waveformView.powerLevel.append(CGFloat(arc4random() % 200))
        //        waveformView.powerLevel = waveformView.powerLevel
        //    }
        
        //        let path = Bundle(for: type(of: self)).path(forResource: "Calling_007_10086", ofType: "wav")
        //        SMAudioFileSampler.sample(url: URL(fileURLWithPath: path!), countPerSecond: 50, completion: { (sampleData) in
        //            DispatchQueue.main.async(execute: {
        //                var tempData = [CGFloat]()
        //                for data in sampleData! {
        //                    tempData.append(CGFloat(data))
        //                }
        //                self.waveformView.powerLevel = tempData
        //            })
        //        })
    }
}
