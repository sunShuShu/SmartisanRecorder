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
    
    deinit {
        refreshLevelTimer?.cancel()
    }
    
    private var timer = SMAudioTimer()
    @IBAction func staticIndicatorAction(_ sender: Any) {
        dashboardView.showComponents([.Axis, .Waveform, .Time, .Flag, .Indicator])
    }
    
    @IBAction func dynamicIncatorAction(_ sender: Any) {
        dashboardView.showComponents([.Axis, .Waveform, .Time, .Flag, .Indicator])
        timer.stop()
        timer.start()
        dashboardView.indicatorView.setMovableLineParameter(updateCurrentPosition: {
            [weak self] in
            if let strongSelf = self {
                return CGFloat(strongSelf.timer.duration / 10)
            } else {
                return 0
            }
        }, indicatorDragged: { (position, isEnd) in
            SMLog("\(position)---\(isEnd)")
        })
        view.setNeedsLayout()
    }
    
    private var refreshLevelTimer: DispatchSourceTimer?
    private var levelArray = [UInt8]()
    @IBAction func timeAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if refreshLevelTimer == nil {
                refreshLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInteractive))
                refreshLevelTimer?.setEventHandler {
                    [weak self] in
                    if let strongSelf = self {
                        strongSelf.dashboardView.waveformView.addPowerLevel(UInt8(arc4random() % 255))
                    }
                }
                refreshLevelTimer?.resume()
            }
            
            dashboardView.setRecordParameters()
            dashboardView.waveformView.setRecordParameters(updatePlayedTime: {
                [weak self] in
                if let strongSelf = self {
                    return CGFloat(strongSelf.timer.duration)
                } else {
                    return 0
                }
            })
            timer.start()
            refreshLevelTimer?.schedule(deadline: .now(), repeating: 1/50.0)
            dashboardView.waveformView.isDynamic = true
        } else {
            refreshLevelTimer?.schedule(deadline: .distantFuture)
            timer.stop()
            dashboardView.waveformView.setPowerLevelArray([UInt8]())
        }
    }
    
    @IBAction func flagAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            dashboardView.indicatorView.setUnmovableAddButtonParameter(buttonActionBlock: { (type) in
                SMLog("\(type) Action")
            })
            dashboardView.setRecordParameters()
            dashboardView.indicatorView.indicatorDragged = {
                (position, isEnd) -> () in
                SMLog("\(position)---\(isEnd)")
            }
        }
    }
    
}
