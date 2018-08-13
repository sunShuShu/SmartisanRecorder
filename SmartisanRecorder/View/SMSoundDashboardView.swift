//
//  SMSoundDashboardView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/11.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

typealias SMTime = CGFloat
typealias SMTimeRange = (start: SMTime, end: SMTime)

class SMSoundDashboardView: SMBaseView {
    //MARK:- views
    struct Component: OptionSet {
        var rawValue: Int
        static let Axis = Component(rawValue: 1 << 0)
        static let Waveform = Component(rawValue: 1 << 1)
        static let Indicator = Component(rawValue: 1 << 2)
        static let Time = Component(rawValue: 1 << 3)
        static let Edit = Component(rawValue: 1 << 4)
        static let Flag = Component(rawValue: 1 << 5)
    }
    
    var timeViewHeight: CGFloat = 16
    
    private(set) lazy var axisView = SMAxisView()
    private(set) lazy var waveformView = SMWaveformView()
    private(set) lazy var indicatorView = SMTimeElapseIndicator()
    private(set) lazy var timeView = SMTimeScaleView()
    private(set) var editView: SMEditSoundView?
    private(set) lazy var flagView = SMFlagView()
    private var components = Component(rawValue: 0)
    
    func showComponents(_ components: Component) {
        self.components = components
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var timeViewHeight: CGFloat = 0
        
        if components.contains(.Time) {
            timeViewHeight = self.timeViewHeight
            if subviews.contains(timeView) == false {
                addSubview(timeView)
            }
            UIView.autoLayout(timeView, bottom: self.bounds.height - timeViewHeight)
        }
        
        if components.contains(.Axis) {
            if subviews.contains(axisView) == false {
                addSubview(axisView)
            }
            UIView.autoLayout(axisView, top: timeViewHeight)
        }
        
        if components.contains(.Waveform) {
            if subviews.contains(waveformView) == false {
                addSubview(waveformView)
            }
            UIView.autoLayout(waveformView, top: timeViewHeight)
        }
        
        if components.contains(.Flag) {
            if subviews.contains(flagView) == false {
                addSubview(flagView)
            }
            UIView.autoLayout(flagView, top: timeViewHeight)
        }
        
        if components.contains(.Indicator) {
            if subviews.contains(indicatorView) == false {
                addSubview(indicatorView)
            }
            UIView.autoLayout(indicatorView, top: timeViewHeight)
        }
        
        if components.contains(.Edit) {
            if let view = editView {
                if subviews.contains(view) == false {
                    addSubview(view)
                }
                UIView.autoLayout(view, top: timeViewHeight)
            }
        }
    }
    
    //MARK:- render
    /// The block need to return current played time. The waveform won't be zoomed. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside. If this property is not nil, the displayTimeRange value will be ignored.
    var updatePlayedTime: (() -> (SMTime))?
    
    /// The waveform view may be zoomed.
    var displayTimeRange: SMTimeRange? {
        didSet {
            guard displayTimeRange != nil &&
                displayTimeRange!.start < displayTimeRange!.end else {
                    return
            }
            renderTimerFireOnce = true
        }
    }
    
    /// The waveform view has two kind of way to update display. If isDynamic is true, the updatePlayedTime will be call when it's time to render screen. If isDymanic is false, waveform view will be render when the updateDisplayRange changed.
    var isDynamic = false {
        didSet {
            if isDynamic && updatePlayedTime == nil {
                assert(false, "updatePlayedTime is nil!")
                return
            }
            renderTimer?.isPaused = !isDynamic
        }
    }
    
    func refreshView() {
        renderTimerFireOnce = true
    }

    private lazy var renderQueue = DispatchQueue(label: "com.sunshushu.SoundDashboardRender", qos: .userInteractive)
    private var renderTimer: CADisplayLink?
    private var renderTimerNeedRemoved = false
    private var renderTimerFireOnce = false {
        didSet {
            if renderTimerFireOnce {
                renderTimer?.isPaused = false
            }
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if renderTimer == nil {
            renderTimer = CADisplayLink(target: self, selector: #selector(render))
            renderTimer?.isPaused = !isDynamic
            renderQueue.async {
                [weak self] in
                self?.renderTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
                RunLoop.current.run()
            }
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        //Only remove render timer in render queue, the timer must be fire.
        renderTimer?.isPaused = false
        renderTimerNeedRemoved = true
    }
    
    @objc private func render() {
        guard renderTimerNeedRemoved == false else {
            //Stop and remove render timer in render queue.
            renderTimer?.isPaused = true
            renderTimer?.invalidate()
            renderTimer?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            renderTimerNeedRemoved = false
            return
        }
        
        if renderTimerFireOnce {
            renderTimer?.isPaused = true
            renderTimerFireOnce = false
        }
        
        if let block = updatePlayedTime {
            let currentTime = block()
            
            if components.contains(.Waveform) {
                waveformView.setTime(currentTime: currentTime, timeRange: nil)
            }
            
            if components.contains(.Time) {
                timeView.setCurrentTime(currentTime)
            }
            
            if components.contains(.Flag) {
                flagView.setCurrentTime(currentTime)
            }
            
        } else if let timeRange = displayTimeRange {
//            if components.contains(.Waveform) {
//                waveformView.setTime(currentTime: nil, timeRange: timeRange)
//            }
            
            assert(false == components.contains(.Time), "Can NOT contain time scale view when the displayTimeRange is set")
            
//            if components.contains(.Flag) {
//                flagView.setCurrentTime(1)
//            }
        }
        
    }
}

extension SMSoundDashboardView {
    func setRecordMode(updatePlayedTime: @escaping () -> (SMTime)) {
        self.updatePlayedTime = updatePlayedTime
        self.waveformView.setRecordMode()
        self.showComponents([.Axis, .Waveform, .Time, .Indicator, .Flag])
    }
    
    func setPlayMode(audioDuration: SMTime, powerLevelData: SMWaveformModel, flagData: SMFlagModel?, updatePlayedTime: @escaping () -> (SMTime)) {
         self.updatePlayedTime = updatePlayedTime
        self.waveformView.setPlayMode(audioDuration: audioDuration, powerLevelData: powerLevelData)
        self.flagView.setflagModel(flagData)
        self.showComponents([.Axis, .Waveform, .Time, .Indicator, .Flag])
    }
    
    func setScalableMode(audioDuration: SMTime, displayRange:SMTimeRange, powerLevelData: SMWaveformModel, flagData: SMFlagModel?) {
        self.waveformView.setScalableMode(audioDuration: audioDuration, powerLevelData: powerLevelData)
        self.flagView.setflagModel(flagData)
        self.displayTimeRange = displayRange
        self.showComponents([.Axis, .Waveform, .Time, .Indicator, .Flag])
    }
    
    func setEditMode(isIntegrated: Bool, extendWidth: CGFloat, audioDuration: SMTime, powerLevelData: SMWaveformModel, flagData: SMFlagModel?) {
        self.editView = SMEditSoundView(isIntegrated: isIntegrated, extendWidth: extendWidth, audioDuration: audioDuration)
        self.waveformView.setScalableMode(audioDuration: audioDuration, powerLevelData: powerLevelData)
        self.flagView.setflagModel(flagData)
        self.showComponents([.Axis, .Waveform, .Edit, .Indicator, .Flag])
    }
}
