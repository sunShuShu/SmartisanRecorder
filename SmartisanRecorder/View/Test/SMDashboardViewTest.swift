//
//  SMDashboardViewTest.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/15.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMDashboardViewTestViewController: SMBaseViewController {
    @IBOutlet weak var dashboardView: SMSoundDashboardView!
    
    private let timer = SMAudioTimer()
    @IBAction func staticIndicatorAction(_ sender: Any) {
        dashboardView.showComponents([.Axis, .Waveform, .Time, .Flag, .Indicator])
        dashboardView.indicatorView = SMTimeElapseIndicator()
    }
    
    @IBAction func dynamicIncatorAction(_ sender: Any) {
        dashboardView.showComponents([.Axis, .Waveform, .Time, .Flag, .Indicator])
        timer.stop()
        timer.start()
        dashboardView.indicatorView = SMTimeElapseIndicator(updateCurrentPosition: {
            [weak self] in
            if let strongSelf = self {
                return CGFloat(strongSelf.timer.duration / 10)
            } else {
                return 0
            }
            }, indicatorDragged: { (position) in
                SMLog("\(position)")
        })
        view.setNeedsLayout()
    }
    
}
