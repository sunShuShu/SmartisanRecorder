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

class SMWaveformView: SMBaseView, RenderViewDelegate {
    static let maxPowerLevel = CGFloat(UInt8.max)
    
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1 {
        didSet {
            if lineWidth < 0.5 {
                assert(false, "Line width should not less than 0.5!")
                lineWidth = oldValue
            }
        }
    }
    
    /// line color
    var lineColor: CGColor = UIColor(rgb256WithR: 160, g: 160, b: 160, alpha: 1).cgColor
    
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

    /// The block need to return current played time. The waveform won't be zoomed. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside. If this property is not nil, the displayTimeRange value will be ignored.
    var updatePlayedTime: (() -> (SMTime))?
    /// The waveform view may be zoomed.
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
    var audioDuration: SMTime = 0 {
        didSet {
            if audioDuration < 0 {
                audioDuration = 0
            }
        }
    }
    
    /// Default = 50
    var dataCountPerSecond: Int = 50
    
    //MARK:- Waveform Data
    var powerLevelData = SMWaveformModel()
    
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
    
    private var lineCount: Int = 0
    private var lineHeightFactor: CGFloat = 0
    private var halfWidth: CGFloat = 0
    private var halfLineWidth: CGFloat = 0
    private var scrollRenderView: SMScrollRenderView?
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = superview?.backgroundColor ?? UIColor.clear
        clipsToBounds = true
        halfWidth = width / 2
        lineCount = Int(width / lineWidth)
        halfLineWidth = lineWidth / 2
        lineHeightFactor = height / SMWaveformView.maxPowerLevel
        if scrollRenderView == nil && scrollOptimizeSettings.isEnable {
            var maxElementWidth: CGFloat = 0
            if scrollOptimizeSettings.isRecordingMode {
                maxElementWidth = 2 * lineWidth + 2
            }
            scrollRenderView = SMScrollRenderView(delegate: self, maxElementWidth: maxElementWidth)
            addSubview(scrollRenderView!)
            
            if scrollOptimizeSettings.isRecordingMode {
                UIView.autoLayout(scrollRenderView!, width: halfWidth , height: height)
            } else {
                UIView.autoLayout(scrollRenderView!)
            }
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
    private var lastRenderedDataIndex = -1
    
    @objc private func render() {
        measure.start()
        
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
        
        var tempPath = CGMutablePath()
        var scrollCanvas: SMRenderView? // It won't be nil if the scroll optimize is enable and need to render entire view.
        var scrollCanvasesArray: [CanvasPosition]? // It won't be nil if the scroll optimize is enable and need to render recording line(s).
        
        defer {
            DispatchQueue.main.async {
                if let canvas = scrollCanvas {
                    // Save the tempPath to canvas, prevent the "self.path" from being overwritten.
                    canvas.path = tempPath
                    canvas.setNeedsDisplay()
                } else if let canvases = scrollCanvasesArray {
                    for info in canvases {
                        let rect = CGRect(x: CGFloat(Int(info.positionX)) - self.halfLineWidth, y: 0, width: self.lineWidth, height: self.height)
                        info.canvas.path = tempPath
                        info.canvas.setNeedsDisplay(rect)
                    }
                } else if self.scrollOptimizeSettings.isEnable == false {
                    self.path = tempPath
                    self.setNeedsDisplay()
                }
            }
            measure.end()
        }
        
        // The key parameters needed for rendering.
        var lineCount = self.lineCount // The number of lines to render
        var startDataIndex: Int = 0
        
        @inline(__always) func addALineToTempPath(level: UInt8, x: CGFloat) {
            let lineHeight = CGFloat(level) * lineHeightFactor
            let startY = (height - lineHeight) / 2
            let endY = startY + lineHeight
            tempPath.move(to: CGPoint(x: x, y: startY))
            tempPath.addLine(to: CGPoint(x: x, y: endY))
        }
        
        if let block = updatePlayedTime {
            let currentTime = block()
            if let delegate = renderDelegate {
                delegate.waveformWillRender(currentTime: currentTime, displayRange: nil)
            }

            // Scroll render optimize
            if let view = scrollRenderView, scrollOptimizeSettings.isEnable {
                #if WaveformLineWidthIsOne
                let scrollViewOffset = CGFloat(dataCountPerSecond) * currentTime - halfWidth
                #else
                let scrollViewOffset = CGFloat(dataCountPerSecond) * currentTime * CGFloat(lineWidth) - halfWidth
                #endif
                if let renderInfo = view.setOffset(scrollViewOffset) {
                    if scrollOptimizeSettings.isRecordingMode {
                        // Clear the old render view
                        renderInfo.canvas.setNeedsClear()
                    } else {
                        // Render a entire view.
                        #if WaveformLineWidthIsOne
                        startDataIndex = Int(renderInfo.canvasOffset / lineWidth)
                        #else
                        startDataIndex = Int(renderInfo.canvasOffset)
                        #endif
                        scrollCanvas = renderInfo.canvas
                    }
                }
                
                if scrollOptimizeSettings.isRecordingMode {
                    // Render a line.
                    scrollCanvasesArray = view.getCanvasPosition(with: scrollViewOffset + halfWidth)
                    for info in scrollCanvasesArray! {
                        //Always render the last data.
                        if let level = powerLevelData.getLast() {
                            addALineToTempPath(level: level, x: CGFloat(Int(info.positionX)))
                        }
                    }
                    return
                } else if scrollCanvas == nil {
                    // No need to render
                    return
                }
            }
            
            // Draw all the lines
            for lineIndex in 0 ..< Int(lineCount) + 1 {
                let currentDataIndex = startDataIndex + lineIndex
                var x = CGFloat(lineIndex)
                #if !WaveformLineWidthIsOne
                if lineWidth != 1 {
                    x = CGFloat(lineIndex) * lineWidth
                }
                #endif
                if let level = powerLevelData.get(currentDataIndex) {
                    addALineToTempPath(level: level, x: x)
                }
            }
            
        } else if let range = displayTimeRange  {
            
            if let delegate = renderDelegate {
                delegate.waveformWillRender(currentTime: nil, displayRange: range)
            }
            let dataAndTimeFactor = CGFloat(powerLevelData.count) / audioDuration
            let startDataLocation = range.start * dataAndTimeFactor
            let endDataLocation = range.end * dataAndTimeFactor
            let scalingFactor = (endDataLocation - startDataLocation) / CGFloat(lineCount)
            
            // Draw all the lines
            for lineIndex in 0 ..< Int(lineCount) + 2 {
                let currentDataIndex = startDataIndex + Int(CGFloat(lineIndex) * scalingFactor)
                var x = CGFloat(lineIndex)
                #if !WaveformLineWidthIsOne
                if lineWidth != 1 {
                    x = CGFloat(lineIndex) * lineWidth
                }
                #endif
                if let level = powerLevelData.get(currentDataIndex) {
                    addALineToTempPath(level: level, x: x)
                }
            }
            
        } else {
            assert(false, "updatePlayedTime and displayTimeRange are nil!")
        }
    }
    
    private func setAppearanceToContext(_ context: CGContext) {
        context.setStrokeColor(self.lineColor)
        context.setLineWidth(self.lineWidth + 0.2)
        context.strokePath()
    }
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.addPath(self.path)
            setAppearanceToContext(context)
        }
    }
    
    func drawRenderView(in ctx: CGContext) {
        setAppearanceToContext(ctx)
    }
}

//MARK:- 
extension SMWaveformView {
    func setRecordParameters(updatePlayedTime: @escaping (() -> (SMTime)), dataCountPerSecond: Int = 50) {
        self.updatePlayedTime = updatePlayedTime
        self.dataCountPerSecond = dataCountPerSecond
        self.scrollOptimizeSettings = (isEnable: true, isRecordingMode: true)
    }
    
    func setPlayParameters(updatePlayedTime: @escaping (() -> (SMTime)), audioDuration: SMTime, powerLevelData: SMWaveformModel) {
        self.updatePlayedTime = updatePlayedTime
        self.audioDuration = audioDuration
        self.powerLevelData = powerLevelData
        self.scrollOptimizeSettings = (isEnable: true, isRecordingMode: false)
    }
    
    func setScalableParameters(displayTimeRange: (start: SMTime, end: SMTime), audioDuration: SMTime, powerLevelData: SMWaveformModel) {
        self.displayTimeRange = displayTimeRange
        self.audioDuration = audioDuration
        self.powerLevelData = powerLevelData
        self.scrollOptimizeSettings = (isEnable: false, isRecordingMode: false)
    }
}
