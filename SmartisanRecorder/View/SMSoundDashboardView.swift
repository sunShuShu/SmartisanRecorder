//
//  SMSoundDashboardView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/11.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMTimeScaleView: SMBaseView {
    
}

class SMFlagView: SMBaseView {
    
}

class SMTimeElapseIndicator: SMBaseView {
    
    /// Default is red.
    var color: CGColor = UIColor(red: 240/255, green: 9/255, blue: 21/255, alpha: 1).cgColor
    
    var lineWidth: CGFloat = 1
    
    var isMovable = false {
        didSet {
            guard isMovable != oldValue else {
                return
            }
            refreshTimer.isPaused = !isMovable
        }
    }
    
    /// 0-1
    var currentPosition: CGFloat = 0.5
    
    /// 0-1
    var updateCurrentPosition: (() -> (CGFloat))?
    
    /// 0-1
    var indicatorDragged: ((CGFloat) -> ())?
    
    private lazy var refreshTimer: CADisplayLink = {
        let timer = CADisplayLink(target: self, selector: #selector(refreshIndicator))
        DispatchQueue.main.async {
            timer.add(to: RunLoop.current, forMode: .UITrackingRunLoopMode)
        }
        return timer
    }()
    
    private lazy var path = CGMutablePath()
    @objc private func refreshIndicator() {
        let tempPath = CGMutablePath()
        var currentPosition = self.currentPosition
        if isMovable {
            if let block = updateCurrentPosition {
                currentPosition = block()
            } else {
                assert(false, "updatePlayedTime is nil!")
                return
            }
        }
        
        let redLineX = currentPosition * self.bounds.width
        let endY = self.bounds.height
        tempPath.move(to: CGPoint(x: redLineX, y: 0))
        tempPath.addLine(to: CGPoint(x: redLineX, y: endY))
        path = tempPath
        setNeedsDisplay()
    }
    
    deinit {
        refreshTimer.isPaused = true
        refreshTimer.invalidate()
        refreshTimer.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        refreshIndicator()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        backgroundColor = UIColor.clear
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }
        contex!.addPath(path)
        contex!.setStrokeColor(color)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}

class SMEditSoundView: SMBaseView {
    
}

class SMAxisView: SMBaseView {
    var color = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1).cgColor
    var lineWidth: CGFloat = 1
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        layer.setNeedsDisplay()
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        let path = CGMutablePath()
        let halfHeight = self.bounds.height / 2
        path.move(to: CGPoint(x: 0, y: halfHeight))
        path.addLine(to: CGPoint(x: self.bounds.width, y: halfHeight))
        ctx.addPath(path)
        ctx.setStrokeColor(color)
        ctx.setLineWidth(lineWidth)
        ctx.drawPath(using: .stroke)
    }
}



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
    
    var timeViewHeight: CGFloat = 15
    
    lazy var axisView = SMAxisView()
    lazy var waveformView = SMWaveformView()
    lazy var indicatorView = SMTimeElapseIndicator()
    lazy var timeView = SMTimeScaleView()
    lazy var editView = SMEditSoundView()
    lazy var flagView = SMFlagView()
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
        
        if components.contains(.Indicator) {
            if subviews.contains(indicatorView) == false {
                addSubview(indicatorView)
            }
            let c = getConstraints(top: timeViewHeight, bottom: 0, view: indicatorView)
            constraints.append(contentsOf: c)
        }
        
        self.addConstraints(constraints)
    }
}
