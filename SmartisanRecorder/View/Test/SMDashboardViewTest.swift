//
//  SMDashboardViewTest.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/15.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation

class SMDashboardViewTestViewController: SMBaseViewController {
    @IBOutlet weak var dashboardView: SMSoundDashboardView!
    
    @IBAction func refreshViewAction(_ sender: Any) {
        dashboardView.showComponents([.Axis, .Waveform, .Time, .Flag, .Indicator])
        view.setNeedsLayout()
        
    }
}
