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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let waveformView = SMWaveformView()
        var simulatData = [CGFloat]()
        for _ in 0..<100 * 50 {
             simulatData.append(CGFloat(arc4random() % 200))
        }
        waveformView.powerLevel = simulatData
        
        waveformView.backgroundColor = UIColor.white
        waveformView.frame = CGRect(x: 0, y: 0, width: waveformView.powerLevel.count, height: 300)
        scrollView.addSubview(waveformView)
        scrollView.contentSize = waveformView.bounds.size
    }
    
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
