//
//  SMMainPageViewController.swift
//  SmartisanRecorder
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class SMMainPageViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var recoder = SMRecorder()
    let waveformView = SMWaveformView()
    let audioMeter = SMAudioMeter(resultRange: 200)
    
    @IBAction func action(_ sender: UIButton) {
        testMerge()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        waveformView.backgroundColor = UIColor.gray
//        waveformView.frame = CGRect(x: 0, y: 0, width: 1000, height: 300)
//        scrollView.addSubview(waveformView)
//        scrollView.contentSize = waveformView.bounds.size
        
//        recoder.record()
//        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerFire), userInfo: nil, repeats: true)
//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 10) {
//            self.recoder.save(with: "Rec_006", completion: { (result) in
//                print(result)
//            })
//        }
        
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
    
    private func testMerge() {
        let outURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/merge\(arc4random() % 9999).wav")
        
        let url1 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "1 Merge_高_中", ofType: "wav")!)
        let url2 = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "低", ofType: "wav")!)
        let editor = SMAudioFileEditor(inputURLs: [url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, url1, url2, ], outputURL: outURL) { (result, error) in
            print(error ?? "Merge success")
        }
        editor!.merge()
    }
    
//    @objc private func timerFire() {
//        let db = recoder.powerLevel
//        let amp = audioMeter.linearLevel(with: db)
//        waveformView.powerLevel.append(CGFloat(amp))
//        waveformView.powerLevel = waveformView.powerLevel
//        
//        waveformView.powerLevel.append(CGFloat(arc4random() % 200))
//        waveformView.powerLevel = waveformView.powerLevel
//    }
    
    private func checkPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission == false {
                var canOpenSettings = false
                let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
                if settingsURL != nil {
                    canOpenSettings = UIApplication.shared.canOpenURL(settingsURL!)
                }
                
                let alert = UIAlertController(title: nil, message: SMLocalize.string(.micPermission), preferredStyle: .alert)
                if canOpenSettings {
                    let goToAction = UIAlertAction(title: SMLocalize.string(.goToSetPersion), style: .default, handler: { (action) in
                        //Go to Settrings
                        UIApplication.shared.openURL(settingsURL!)
                    })
                    let cancelAction = UIAlertAction(title: SMLocalize.string(.cancel), style: .cancel, handler: nil)
                    alert.addAction(goToAction)
                    alert.addAction(cancelAction)
                    
                } else {
                    let okAction = UIAlertAction(title: SMLocalize.string(.ok), style: .default, handler: nil)
                    alert.addAction(okAction)
                }
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
