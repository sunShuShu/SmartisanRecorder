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

protocol WaveformRenderDelegate: class {
    
    /// You can do the custum render work when waveform will be rended. currentTime and displayRange are not going to be non-optional.
    ///
    /// - Parameters:
    ///   - currentTime: current time
    ///   - displayRange: waveform display range
    func waveformWillRender(currentTime: CGFloat?, displayRange: (start: CGFloat, end: CGFloat)?);
}

class SMWaveformView: SMBaseView {
    static let maxPowerLevel = CGFloat(UInt8.max)
    
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1 {
        didSet {
            guard lineWidth > 0 else {
                assert(false, "Line width <= 0!")
            }
        }
    }
    
    /// line color
    var lineColor: CGColor = UIColor.black.cgColor
    
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
    
    func refreshView() {
        renderTimerFireOnce = true
    }
    
    weak var renderDelegate: WaveformRenderDelegate?
    
    //MARK:- Display Location
    private lazy var renderQueue = DispatchQueue(label: "com.sunshushu.WaveformRender", qos: .userInteractive)

    /// The block need to return current played time. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside.
    var updatePlayedTime: (() -> (CGFloat))?
    var displayTimeRange: (start: CGFloat, end: CGFloat)? {
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
    var audioDuration: CGFloat = 0
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
            renderQueue.async {
                [weak self] in
                self?.renderTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
                RunLoop.current.run()
            }
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        measure.getReport()
        
        //Only remove render timer in render queue, the timer must be fire.
        renderTimer?.isPaused = false
        renderTimerNeedRemoved = true
    }
    
    private var lineCount: CGFloat = 0
    private var halfLineCount: CGFloat = 0
    private var lineHeightFactor: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        lineCount = width / lineWidth
        halfLineCount = lineCount / 2
        lineHeightFactor = height / SMWaveformView.maxPowerLevel
    }
    
    //MARK:-
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
        let tempPath = CGMutablePath()
        defer {
            DispatchQueue.main.async {
                self.path = tempPath
                self.setNeedsDisplay()
            }
        }
        
        //Get current played time
        let isDynamic = self.isDynamic
        var currentTime: CGFloat = 0
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
            audioDuration = CGFloat(powerLevelDataCount) / cps
        }
        guard audioDuration > 0 else {
            return
        }
        
        let startDataLocation: CGFloat
        let scalingFactor: CGFloat
        let dataAndTimeFactor = CGFloat(powerLevelDataCount) / audioDuration
        
        if isDynamic {
            let currentDataLocation = currentTime * dataAndTimeFactor
            startDataLocation = currentDataLocation - halfLineCount
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
        let displayLocationOffset = startDataLocation - CGFloat(startDataIndex)
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
                if lineWidth > 1 {
                    x *= lineWidth
                }
                
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
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }

        contex!.addPath(path)
        contex!.setStrokeColor(lineColor)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}

extension SMWaveformView {
    func setRecordParameters(updatePlayedTime: @escaping (() -> (CGFloat)), dataCountPerSecond: CGFloat = 50) {
        self.updatePlayedTime = updatePlayedTime
        self.dataCountPerSecond = dataCountPerSecond
    }
    
    func setPlayParameters(updatePlayedTime: @escaping (() -> (CGFloat)), audioDuration: CGFloat, powerLevelArray: [UInt8]) {
        self.updatePlayedTime = updatePlayedTime
        self.audioDuration = audioDuration
        self.setPowerLevelArray(powerLevelArray)
    }
    
    func setScalableParameters(displayTimeRange: (start: CGFloat, end: CGFloat), audioDuration: CGFloat, powerLevelArray: [UInt8]) {
        self.displayTimeRange = displayTimeRange
        self.audioDuration = audioDuration
        self.setPowerLevelArray(powerLevelArray)
    }
}
