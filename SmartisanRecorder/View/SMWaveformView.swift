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

class SMWaveformView: SMBaseView {
    static let maxPowerLevel = CGFloat(UInt8.max)
    //MARK:- Appearance Settings
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1 {
        didSet {
            guard lineWidth > 0 else {
                lineWidth = oldValue
                assert(false)
            }
            lineCount = width / lineWidth
        }
    }
    /// line color
    var color: CGColor = UIColor.black.cgColor
    
    /// The waveform view has two kind of way to update display. If isDynamic is true, the updatePlayedTime will be call when it's time to render screen. If isDymanic is false, waveform view will be render when the updateDisplayRange changed.
    var isDynamic = false {
        didSet {
            guard isDynamic != oldValue else {
                return
            }
            shiftIsDynamic()
        }
    }
    
    //MARK:- Display Location
    private lazy var renderQueue = DispatchQueue(label: "com.sunshushu.WaveformRenderQueue", qos: .userInteractive)

    /// The block need to return current played time. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside.
    var updatePlayedTime: (() -> (CGFloat))?
    var displayTimeRange: (start: CGFloat, end: CGFloat)? {
        didSet {
            guard displayTimeRange != nil &&
                displayTimeRange!.start < displayTimeRange!.end else {
                return
            }
            isDynamic = false
            renderQueue.async {
                self.render()
            }
        }
    }
    
    //MARK:- Audio Duration
    /// The property should be set if autio length is fixed.
    var audioDuration: CGFloat = 0
    /// This property is required if the audio length is not fixed when rendering, such as a real-time recording. If this property is set, the length of the audio will be automatically calculated using the power level data count, and the audioDuration value will be ignored.
    var dataCountPerSecond: CGFloat?
    private var powerLevelDataCount:Int = 0
    
    //MARK:- Waveform Data
    private lazy var powerLevelArray = [UInt8]()
    //The function should NOT be invoked frequently. When real-time recoding, the addPowerLevel() is recommended.
    func setPowerLevelArray(_ array: [UInt8]) {
        objc_sync_enter(self)
        powerLevelArray = array
        powerLevelDataCount = array.count
        objc_sync_exit(self)
    }
    // The function should be used if the waveform is used to display the real-time recording data.In order to optimize performance, after the interface is called, the previous data is removed, and only the last data to be displayed is retained.
    func addPowerLevel(_ level: UInt8) {
        objc_sync_enter(self)
        powerLevelArray.append(level)
        if CGFloat(powerLevelArray.count + 2) > lineCount {
            powerLevelArray.removeFirst()
        }
        powerLevelDataCount += 1
        objc_sync_exit(self)
    }
    
    //MARK:-
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        measure.getReport()
        
        //Only remove render timer in render queue, the timer must be fire.
        renderTimer?.isPaused = false
        renderTimerNeedRemoved = true
    }
    
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private var lineCount: CGFloat = 0 {
        didSet {
            halfLineCount = lineCount / 2
        }
    }
    private var halfLineCount: CGFloat = 0
    private var lineHeightFactor: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        width = self.bounds.size.width
        height = self.bounds.size.height
        lineCount = width / lineWidth
        lineHeightFactor = height / SMWaveformView.maxPowerLevel
    }
    
    //MARK:-
//    private lazy var lineHeightCache = [Int:CGFloat]()
    private var renderTimer: CADisplayLink?
    private var renderTimerNeedRemoved = false
    private func shiftIsDynamic() {
        if renderTimer == nil {
            renderTimer = CADisplayLink(target: self, selector: #selector(render))
            renderTimerNeedRemoved = false
            renderQueue.async {
                [weak self] in
                self?.renderTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
                RunLoop.current.run()
            }
        } else {
            if isDynamic {
                guard updatePlayedTime != nil else {
                    assert(false, "updatePlayedTime is not set!")
                }
            }
            renderTimer?.isPaused = !isDynamic
        }
    }
    
    private var path = CGMutablePath()
    @objc func render() {
        measure.start()
        //Stop and remove render timer in render queue.
        guard renderTimerNeedRemoved == false else {
            renderTimer?.isPaused = true
            renderTimer?.invalidate()
            renderTimer?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            return
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
        }

        objc_sync_enter(self)
        let powerLevelArray = self.powerLevelArray
        let powerLevelDataCount = self.powerLevelDataCount
        objc_sync_exit(self)
        
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
        let missDataCount = powerLevelDataCount - powerLevelArray.count
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
            
            if currentDataIndex < 0 || currentDataIndex >= powerLevelArray.count {
                continue
            } else {
                var x = (CGFloat(lineIndex) - displayLocationOffset)
                if lineWidth > 1 {
                    x *= lineWidth
                }
                
                let level = powerLevelArray[currentDataIndex]
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
        contex!.setStrokeColor(color)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}
