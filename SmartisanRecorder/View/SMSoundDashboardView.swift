//
//  SMSoundDashboardView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/11.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMSoundDashboardView: SMBaseView {
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
    private(set) lazy var editView = SMEditSoundView()
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
            if subviews.contains(editView) == false {
                addSubview(editView)
            }
            UIView.autoLayout(editView, top: timeViewHeight)
        }
    }
}

extension SMSoundDashboardView: WaveformRenderDelegate {
    func waveformWillRender(currentTime: CGFloat?, displayRange: (start: CGFloat, end: CGFloat)?) {
        if components.contains(.Time) && currentTime != nil {
            timeView.setCurrentTime(currentTime!)
        }
        
        if components.contains(.Flag) {
            if currentTime != nil {
                flagView.setCurrentTime(currentTime!)
            } else if displayRange != nil {
                //TODO: 
            }
        }
    }
    
    func setRecordParameters() {
        self.waveformView.renderDelegate = self
        self.showComponents([.Axis, .Waveform, .Time, .Indicator, .Flag])
    }
}
