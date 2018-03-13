//
//  SMWaveformView.swift
//  SmartisanRecorder
//
//  Created by sunda on 08/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

typealias SMTime = CGFloat

protocol WaveformRenderDelegate: class {
    
    /// You can do the custum render work when waveform will be rended. currentTime and displayRange are not going to be non-optional. Don't make time-consuming operations inside!
    ///
    /// - Parameters:
    ///   - currentTime: current time
    ///   - displayRange: waveform display range
    func waveformWillRender(currentTime: SMTime?, displayRange: (start: SMTime, end: SMTime)?);
}

class SMWaveformView: SMBaseView, SMLayerDelegate {
    static let maxPowerLevel = CGFloat(UInt8.max)
    
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1 {
        didSet {
            guard lineWidth > 0 else {
                assert(false, "Line width <= 0!")
                lineWidth = oldValue
            }
        }
    }
    
    /// line color
    var lineColor: CGColor = UIColor(rgb256WithR: 160, g: 160, b: 160, alpha: 1).cgColor
    
    /// The waveform view has two kind of way to update display. If isDynamic is true, the updatePlayedTime will be call when it's time to render screen. If isDymanic is false, waveform view will be render when the updateDisplayRange changed.
    var isDynamic = false {
        didSet {
            if isDynamic {
                guard updatePlayedTime != nil else {
                    assert(false, "updatePlayedTime is not set!")
                }
            }
            renderTimer?.isPaused = !isDynamic
        }
    }
    
    
    /// default = (false, false).
    var scrollOptimizeSettings: (isEnable: Bool, isRecordingMode: Bool) = (false, false) {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsLayout()
            }
        }
    }
    
    func refreshView() {
        renderTimerFireOnce = true
    }
    
    weak var renderDelegate: WaveformRenderDelegate?
    
    //MARK:- Display Location
    private lazy var renderQueue = DispatchQueue(label: "com.sunshushu.WaveformRender", qos: .userInteractive)

    /// The block need to return current played time. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside.
    var updatePlayedTime: (() -> (SMTime))?
    var displayTimeRange: (start: SMTime, end: SMTime)? {
        didSet {
            guard displayTimeRange != nil &&
                displayTimeRange!.start < displayTimeRange!.end else {
                return
            }
            renderTimerFireOnce = true
        }
    }
    
    //MARK:- Audio Duration
    /// The property should be set if autio length is fixed.
    var audioDuration: SMTime = 0
    /// This property is required if the audio length is not fixed when rendering, such as a real-time recording. If this property is set, the length of the audio will be automatically calculated using the power level data count, and the audioDuration value will be ignored.
    var dataCountPerSecond: CGFloat?
    private var powerLevelDataCount:Int = 0
    
    //MARK:- Waveform Data
    private var powerLevelArray: [UInt8]?
    //The function should NOT be invoked frequently. When real-time recoding, the addPowerLevel() is recommended.
    func setPowerLevelArray(_ array: [UInt8]?) {
        objc_sync_enter(self)
        powerLevelArray = array
        if array != nil {
            powerLevelDataCount = array!.count
        } else {
            powerLevelDataCount = 0
        }
        objc_sync_exit(self)
    }
    // The function should be used if the waveform is used to display the real-time recording data.In order to optimize performance, after the interface is called, the previous data is removed, and only the last data to be displayed is retained.
    func addPowerLevel(_ level: UInt8) {
        objc_sync_enter(self)
        if powerLevelArray == nil {
            powerLevelArray = [UInt8]()
        }
        powerLevelArray!.append(level)
        if CGFloat(powerLevelArray!.count + 2) > lineCount {
            powerLevelArray!.removeFirst()
        }
        powerLevelDataCount += 1
        objc_sync_exit(self)
    }
    
    //MARK:-
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
        measure.getReport(from: self)
        
        //Only remove render timer in render queue, the timer must be fire.
        renderTimer?.isPaused = false
        renderTimerNeedRemoved = true
    }
    
    private var lineCount: CGFloat = 0
    private var halfLineCount: CGFloat = 0
    private var lineHeightFactor: CGFloat = 0
    private var scrollRenderView: SMScrollRenderView?
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        lineCount = width / lineWidth
        halfLineCount = lineCount / 2
        lineHeightFactor = height / SMWaveformView.maxPowerLevel
        if scrollRenderView == nil && scrollOptimizeSettings.isEnable {
            scrollRenderView = SMScrollRenderView(delegate: self)
            scrollRenderView!.frame = self.frame
            addSubview(scrollRenderView!)
            UIView.autoLayout(scrollRenderView!)
        } else if let view = scrollRenderView, scrollOptimizeSettings.isEnable == false {
            view.removeFromSuperview()
            scrollRenderView = nil
        }
    }
    
    //MARK:- Render
    private var renderTimer: CADisplayLink?
    private var renderTimerNeedRemoved = false
    private var renderTimerFireOnce = false {
        didSet {
            if renderTimerFireOnce {
                renderTimer?.isPaused = false
            }
        }
    }
    
    private var path = CGMutablePath()
    private var currentScrollCanvas: CALayer? = nil
    @objc private func render() {
        measure.start()
        
        //Stop and remove render timer in render queue.
        guard renderTimerNeedRemoved == false else {
            renderTimer?.isPaused = true
            renderTimer?.invalidate()
            renderTimer?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            return
        }
        
        if renderTimerFireOnce {
            renderTimer?.isPaused = true
            renderTimerFireOnce = false
        }
        
        //The view is refreshed regardless of whether the rendered data is successful or not.
        var tempPath = CGMutablePath()
        var scrollCanvas: CALayer? = nil
        defer {
            if scrollCanvas != nil || scrollOptimizeSettings.isEnable == false {
                DispatchQueue.main.async {
                    self.path = tempPath
                    if self.scrollOptimizeSettings.isEnable == false {
                        self.setNeedsDisplay()
                    } else {
                        scrollCanvas?.setNeedsDisplay()
                        scrollCanvas = nil
                    }
                }
            }
        }
        
        //Get current played time
        let isDynamic = self.isDynamic
        var currentTime: SMTime = 0
        if isDynamic {
            let block = updatePlayedTime
            guard block != nil else {
                return
            }
            currentTime = block!()
            if let delegate = renderDelegate {
                delegate.waveformWillRender(currentTime: currentTime, displayRange: nil)
            }
        } else {
            if let delegate = renderDelegate {
                delegate.waveformWillRender(currentTime: nil, displayRange: displayTimeRange)
            }
        }

        objc_sync_enter(self)
        let powerLevelArray = self.powerLevelArray
        let powerLevelDataCount = self.powerLevelDataCount
        objc_sync_exit(self)
        guard powerLevelArray != nil else {
            return
        }
        
        //Get duration
        var audioDuration = self.audioDuration
        if let cps = dataCountPerSecond {
            audioDuration = SMTime(powerLevelDataCount) / cps
        }
        guard audioDuration > 0 else {
            return
        }
        
        var startDataLocation: CGFloat
        let scalingFactor: CGFloat
        let dataAndTimeFactor = CGFloat(powerLevelDataCount) / audioDuration
        var lineCount = self.lineCount
        var scrollOptimizelineX: CGFloat? = nil
        
        if isDynamic {
            let currentDataLocation = currentTime * dataAndTimeFactor
            startDataLocation = currentDataLocation - halfLineCount
            if let view = scrollRenderView, scrollOptimizeSettings.isEnable {
                let scrollViewOffset = startDataLocation * lineWidth
                if let renderInfo = view.setOffset(scrollViewOffset) {
                    startDataLocation = renderInfo.canvasOffset / lineWidth
                    scrollCanvas = renderInfo.canvas
                    if scrollOptimizeSettings.isRecordingMode {
//                        scrollOptimizelineX = renderInfo.lineX
                        lineCount = 1
                        if self.currentScrollCanvas == scrollCanvas {
                            tempPath = self.path // Use old path to add one line
                        } else {
                            self.currentScrollCanvas = scrollCanvas
                        }
                    }
                } else {
                    // No need to render
                    return
                }
            }
            scalingFactor = 1
        } else {
            let range = displayTimeRange
            guard range != nil else {
                return
            }
            startDataLocation = range!.start * dataAndTimeFactor
            let endDataLocation = range!.end * dataAndTimeFactor
            scalingFactor = (endDataLocation - startDataLocation) / lineCount
        }

        // Calculate startDataIndex and displayLocationOffset
        var startDataIndex = Int(startDataLocation)
        var displayLocationOffset: CGFloat = 0
        if scrollOptimizeSettings.isEnable == false {
            displayLocationOffset = startDataLocation - CGFloat(startDataIndex)
        }
        let missDataCount = powerLevelDataCount - powerLevelArray!.count
        if missDataCount > 0 {
            startDataIndex -= missDataCount
        }
        
        for lineIndex in 0 ..< Int(lineCount) + 2 {
            var currentDataIndex = startDataIndex
            if scalingFactor != 1 {
                currentDataIndex += Int(CGFloat(lineIndex) * scalingFactor)
            } else {
                currentDataIndex += lineIndex
            }
            
            if currentDataIndex < 0 || currentDataIndex >= powerLevelArray!.count {
                continue
            } else {
                var x = (CGFloat(lineIndex) - displayLocationOffset)
                if let lineX = scrollOptimizelineX {
                    x = lineX
                } else if lineWidth > 1 {
                    x *= lineWidth
                }
                
                //Add one line to path
                let level = powerLevelArray![currentDataIndex]
                let lineHeight = CGFloat(level) * lineHeightFactor
                let startY = (height - lineHeight) / 2
                let endY = startY + lineHeight
                tempPath.move(to: CGPoint(x: x, y: startY))
                tempPath.addLine(to: CGPoint(x: x, y: endY))
            }
        }
        
        measure.end()
    }
    
    private func drawToContext(_ context: CGContext) {
        context.addPath(path)
        context.setStrokeColor(lineColor)
        context.setLineWidth(lineWidth)
        context.drawPath(using: .stroke)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            drawToContext(context)
        }
    }
    
    //MARK:- ScrollRender Delegate
    func drawSMLayer(in ctx: CGContext) {
        drawToContext(ctx)
    }
}

extension SMWaveformView {
    func setRecordParameters(updatePlayedTime: @escaping (() -> (SMTime)), dataCountPerSecond: CGFloat = 50) {
        self.updatePlayedTime = updatePlayedTime
        self.dataCountPerSecond = dataCountPerSecond
        self.scrollOptimizeSettings = (isEnable: true, isRecordingMode: true)
    }
    
    func setPlayParameters(updatePlayedTime: @escaping (() -> (SMTime)), audioDuration: SMTime, powerLevelArray: [UInt8]) {
        self.updatePlayedTime = updatePlayedTime
        self.audioDuration = audioDuration
        self.setPowerLevelArray(powerLevelArray)
        self.scrollOptimizeSettings = (isEnable: true, isRecordingMode: false)
    }
    
    func setScalableParameters(displayTimeRange: (start: SMTime, end: SMTime), audioDuration: SMTime, powerLevelArray: [UInt8]) {
        self.displayTimeRange = displayTimeRange
        self.audioDuration = audioDuration
        self.setPowerLevelArray(powerLevelArray)
        self.scrollOptimizeSettings = (isEnable: false, isRecordingMode: false)
    }
}
