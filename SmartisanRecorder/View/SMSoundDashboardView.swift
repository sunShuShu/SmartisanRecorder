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
    var widthPerSecond: CGFloat = 50 {
        didSet {
            if widthPerSecond <= 0 {
                assert(false, "widthPerSecond can not be less than or equle 0!")
            }
        }
    }
    var lineWidth: CGFloat = 0.5
    var middleScaleHight: CGFloat = 1
    var lineColor: CGColor = UIColor(rgb256WithR: 183, g: 183, b: 183, alpha: 1).cgColor
    var timeColor: UIColor = UIColor(rgb256WithR: 130, g: 130, b: 130, alpha: 1)
    var timeFormat: String = "HH:mm:SS"
    var timeStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        return style
    }()
    
    private var halfLineWidth: CGFloat = 0
    private var halfWidthPerSecond:CGFloat = 0
    private var labelCount = 0
    private var bottomLineStart = CGPoint.zero
    private var bottomLineEnd = CGPoint.zero
    private var shortScaleLineStartY: CGFloat = 0
    private var shortScaleLineEndY: CGFloat = 0
    private var timeSize = CGSize.zero
    private var timeFont = UIFont.systemFont(ofSize: 8)
    private var timeAttributes: [NSAttributedStringKey:Any]?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.clear
        halfLineWidth = lineWidth / 2
        timeIndicatorOffset = width / widthPerSecond / 2
        halfWidthPerSecond = widthPerSecond / 2
        labelCount = Int(width / widthPerSecond + 1)
        bottomLineStart = CGPoint(x: 0, y: height - halfLineWidth)
        bottomLineEnd = CGPoint(x: width, y: height - halfLineWidth)
        shortScaleLineStartY = height - lineWidth
        shortScaleLineEndY = shortScaleLineStartY - middleScaleHight
        timeSize = CGSize(width: widthPerSecond, height: height - middleScaleHight * 2)
        timeFont = UIFont.systemFont(ofSize: timeSize.height * 0.7)
        timeAttributes = [NSAttributedStringKey.font:timeFont, NSAttributedStringKey.foregroundColor:timeColor, NSAttributedStringKey.paragraphStyle:timeStyle]
        
        self.clipsToBounds = false
    }
    
    private let renderQueue = DispatchQueue(label: "com.sunshushu.TimeScaleRender", qos: .userInteractive)
    private var timeIndicatorOffset: CGFloat = 0
    private lazy var path = CGMutablePath()
    private lazy var timeLabelInfo = [(String, CGRect)]()
    
    func setCurrentTime(_ currentTime: CGFloat) {
        renderQueue.async {
            [weak self] in
            if let strongSelf = self {
                strongSelf.measure.start()
                
                let tempPath = CGMutablePath()
                var tempTimeLabelInfo = [(String, CGRect)]()
                
                tempPath.move(to: strongSelf.bottomLineStart)
                tempPath.addLine(to: strongSelf.bottomLineEnd)
                
                let startTime = currentTime - strongSelf.timeIndicatorOffset
                let labelOffset = startTime.truncatingRemainder(dividingBy: 1) * strongSelf.widthPerSecond
                for index in 0..<strongSelf.labelCount {
                    let currentLabel = index + Int(startTime)
                    if currentLabel < 0 {
                        continue
                    } else {
                        // line
                        let x = CGFloat(index) * strongSelf.widthPerSecond - labelOffset
                        tempPath.move(to: CGPoint(x: x, y: 0))
                        tempPath.addLine(to: CGPoint(x: x, y: strongSelf.height))
                        let shortScaleLineX = x + strongSelf.halfWidthPerSecond
                        tempPath.move(to: CGPoint(x: shortScaleLineX, y: strongSelf.shortScaleLineStartY))
                        tempPath.addLine(to: CGPoint(x: shortScaleLineX, y: strongSelf.shortScaleLineEndY))
                        
                        //time label
                        let timeString = "00:00:00"
                        let rect = CGRect(origin: CGPoint(x: x, y: 0), size: strongSelf.timeSize)
                        tempTimeLabelInfo.append((timeString, rect))
                    }
                }
                DispatchQueue.main.async {
                    strongSelf.path = tempPath
                    strongSelf.timeLabelInfo = tempTimeLabelInfo
                    strongSelf.setNeedsDisplay()
                }
                
                strongSelf.measure.end()
            }
        }
    }
    
    deinit {
        measure.getReport()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }
        for (string, rect) in timeLabelInfo {
            (string as NSString).draw(in: rect, withAttributes: timeAttributes)
        }
        contex!.addPath(path)
        contex!.setStrokeColor(lineColor)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}

class SMFlagView: SMBaseView {
    
}

class SMTimeElapseIndicator: SMBaseView {
    
    /// Default is red.
    var color: CGColor = UIColor(rgb256WithR: 240, g: 9, b: 21, alpha: 1).cgColor
    
    var lineWidth: CGFloat = 1
    
    var isMovable = false {
        didSet {
            guard isMovable != oldValue else {
                return
            }
            setupTimer()
        }
    }
    
    /// 0-1
    var currentPosition: CGFloat = 0.5
    
    /// 0-1
    var updateCurrentPosition: (() -> (CGFloat))?
    
    /// The position user touched.
    var indicatorDragged: ((CGFloat) -> ())?
    
    private var refreshTimer: CADisplayLink?
    private func setupTimer() {
        if isMovable && refreshTimer == nil {
            refreshTimer = CADisplayLink(target: self, selector: #selector(refreshIndicator))
            DispatchQueue.main.async {
                self.refreshTimer?.add(to: RunLoop.current, forMode: .commonModes)
                self.needRemoveTimer = false
            }
        }
        refreshTimer?.isPaused = !isMovable
    }
    
    private lazy var path = CGMutablePath()
    @objc private func refreshIndicator() {
        guard needRemoveTimer == false else {
            refreshTimer?.isPaused = true
            refreshTimer?.invalidate()
            refreshTimer?.remove(from: RunLoop.current, forMode: .commonModes)
            needRemoveTimer = false
            return
        }
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        refreshIndicator()
    }
    
    private var needRemoveTimer = false
    override func removeFromSuperview() {
        super.removeFromSuperview()
        needRemoveTimer = true
        refreshTimer?.isPaused = false
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setupTimer()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
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

extension SMTimeElapseIndicator {
    func setMovableParameter(updateCurrentPosition: (() -> (CGFloat))?, indicatorDragged: ((CGFloat) -> ())?) {
        self.isMovable = true
        self.updateCurrentPosition = updateCurrentPosition
        self.indicatorDragged = indicatorDragged
    }
    
    func setUnmovableParameter(currentPosition: CGFloat) {
        self.isMovable = false
        self.currentPosition = currentPosition
    }
}

class SMEditSoundView: SMBaseView {
    
}

class SMAxisView: SMBaseView {
    var color = UIColor(rgb256WithR: 180, g: 180, b: 180, alpha: 1).cgColor
    var lineWidth: CGFloat = 0.8
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }
        let path = CGMutablePath()
        let halfHeight = self.bounds.height / 2
        path.move(to: CGPoint(x: 0, y: halfHeight))
        path.addLine(to: CGPoint(x: self.bounds.width, y: halfHeight))
        contex!.addPath(path)
        contex!.setStrokeColor(color)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
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
