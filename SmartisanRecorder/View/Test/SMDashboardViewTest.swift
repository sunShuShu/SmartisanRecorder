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
    private var levelArray: SMWaveformModel? = {
        return SMWaveformModel(fileName: "test")
    }()
    @IBAction func timeAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if refreshLevelTimer == nil {
                refreshLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInteractive))
                refreshLevelTimer?.setEventHandler {
                    [weak self] in
                    if let strongSelf = self {
                        strongSelf.levelArray?.add(UInt8(arc4random() % 255))
                    }
                }
                refreshLevelTimer?.resume()
            }
            
            dashboardView.setRecordMode(updatePlayedTime: {
                [weak self] in
                if let strongSelf = self {
                    return CGFloat(strongSelf.timer.duration)
                } else {
                    return 0
                }
            })

            timer.start()
            refreshLevelTimer?.schedule(deadline: .now(), repeating: 1/50.0)
            dashboardView.isDynamic = true
            
//            var times = [SMTime]()
//            for index in 1..<100 {
//                times.append(CGFloat(index) - 0.1)
//            }
//            dashboardView.flagView.setFlagsTimeArray(times)
        } else {
            refreshLevelTimer?.schedule(deadline: .distantFuture)
            timer.stop()
        }
        dashboardView.waveformView.powerLevelData = levelArray
    }
    
    @IBAction func flagAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            let waveformModel = SMWaveformModel(fileName: "maximum")
            let flagModel = SMFlagModel(fileName: "maximum")
            dashboardView.setPlayMode(audioDuration: 72*3600, powerLevelData: waveformModel!, flagData: flagModel) {
                [weak self] in
                if let strongSelf = self {
                    return CGFloat(strongSelf.timer.duration)
                } else {
                    return 0
                }
            }
            dashboardView.isDynamic = true
            timer.start()
        }
    }
    
    @IBAction func zoomAction(_ sender: UIButton) {
        let start = CGFloat(arc4random() % 10000) / 100
        let end = CGFloat(arc4random() % 10000) / 100
//        let end = start + 10
        let waveformModel = SMWaveformModel(fileName: "maximum")
        let flagModel = SMFlagModel(fileName: "maximum")
        dashboardView.setScalableMode(audioDuration: 72*3600, displayRange: (start, end), powerLevelData: waveformModel!, flagData: flagModel)
        dashboardView.displayTimeRange = (min(start, end), max(start, end))
    }
    
    @IBAction func editAction(_ sender: Any) {
        let start = CGFloat(arc4random() % 10000) / 100
        let end = CGFloat(arc4random() % 10000) / 100
        let waveformModel = SMWaveformModel(fileName: "maximum")
        let flagModel = SMFlagModel(fileName: "maximum")
        dashboardView.setEditMode(isIntegrated: true, extendWidth: 12, audioDuration: 72*3600, powerLevelData: waveformModel!, flagData: flagModel)
        dashboardView.displayTimeRange = (min(start, end), max(start, end))
    }
    
}
