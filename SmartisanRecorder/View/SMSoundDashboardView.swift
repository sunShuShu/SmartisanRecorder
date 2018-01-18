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
        
        func getConstraints(top: CGFloat, bottom: CGFloat, view: UIView) -> [NSLayoutConstraint] {
            view.translatesAutoresizingMaskIntoConstraints = false
            let vflH = "H:|[view]|"
            let vflV = "V:|-top-[view]-bottom-|"
            let metrics = ["top": top, "bottom": bottom]
            let viewBind = ["view" : view]
            let options = NSLayoutFormatOptions(rawValue: 0)
            let h = NSLayoutConstraint.constraints(withVisualFormat: vflH, options: options, metrics: nil, views: viewBind)
            let v = NSLayoutConstraint.constraints(withVisualFormat: vflV, options: options, metrics: metrics, views: viewBind)
            var constraints = [NSLayoutConstraint]()
            constraints.append(contentsOf: h)
            constraints.append(contentsOf: v)
            return constraints
        }
        
        var constraints = [NSLayoutConstraint]()
        var timeViewHeight: CGFloat = 0
        
        if components.contains(.Time) {
            timeViewHeight = self.timeViewHeight
            if subviews.contains(timeView) == false {
                addSubview(timeView)
            }
            let c = getConstraints(top: 0, bottom: self.bounds.height - timeViewHeight, view: timeView)
            constraints.append(contentsOf: c)
        }
        
        if components.contains(.Axis) {
            if subviews.contains(axisView) == false {
                addSubview(axisView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: axisView)
            constraints.append(contentsOf: c)
        }
        
        if components.contains(.Waveform) {
            if subviews.contains(waveformView) == false {
                addSubview(waveformView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: waveformView)
            constraints.append(contentsOf: c)
        }
        
        if components.contains(.Flag) {
            if subviews.contains(flagView) == false {
                addSubview(flagView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: flagView)
            constraints.append(contentsOf: c)
        }
        
        if components.contains(.Indicator) {
            if subviews.contains(indicatorView) == false {
                addSubview(indicatorView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: indicatorView)
            constraints.append(contentsOf: c)
        }
        
        if components.contains(.Edit) {
            if subviews.contains(editView) == false {
                addSubview(editView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: editView)
            constraints.append(contentsOf: c)
        }
        
        self.addConstraints(constraints)
    }
}

extension SMSoundDashboardView: WaveformRenderDelegate {
    func waveformWillRender(currentTime: CGFloat?, displayRange: (start: CGFloat, end: CGFloat)?) {
        if components.contains(.Time) && currentTime != nil {
            timeView.setCurrentTime(currentTime!)
        }
    }
    
    func setRecordParameters() {
        self.waveformView.renderDelegate = self
        self.showComponents([.Axis, .Waveform, .Time, .Indicator, .Flag])
    }
}
