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
    
    private var recoder = SMRecorder()
    @IBOutlet weak var waveformView: SMWaveformView!
    let audioMeter = SMAudioMeter(resultRange: 200)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func action(_ sender: UIButton) {
        waveformView.updatePlayedTime = {
            return CGFloat(arc4random()%100)
        }
        waveformView.isDynamic = !sender.isSelected
        sender.isSelected = !sender.isSelected
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
