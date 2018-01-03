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

class SMWaveformView: UIView {
    static let maxPowerLevel = CGFloat(UInt8.max)
    
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1 {
        didSet {
            guard lineWidth > 0 else {
                lineWidth = oldValue
                assert(false)
            }
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
//                [weak self] in
                self.render()
            }
        }
    }
    
    /// If isDynamic is true, the value should be set.
//    var dataCountPerSecond = 50
    var audioDuration: CGFloat = 0
    var powerLevelArray: [UInt8] = Array()
    
    //MARK:-
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        //Only remove render timer in render queue, the timer must be fire.
        renderTimer?.isPaused = false
        renderTimerNeedRemoved = true
    }
    
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        width = self.bounds.size.width
        height = self.bounds.size.height
    }
    
    //MARK:-
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
        //Stop and remove render timer in render queue.
        guard renderTimerNeedRemoved == false else {
            renderTimer?.isPaused = true
            renderTimer?.invalidate()
            renderTimer?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            return
        }
        
        let isDynamic = self.isDynamic
        var currentTime: CGFloat = 0
        if isDynamic {
            let block = updatePlayedTime
            guard block != nil else {
                return
            }
            currentTime = block!()
        }
        
        let duration = audioDuration
        guard duration > 0 else {
            return
        }
        
        let tempPath = CGMutablePath()
        let startDataLocation: CGFloat
        let scalingFactor: CGFloat
        
        if isDynamic {
            let currentDataLocation = currentTime * CGFloat(powerLevelArray.count) / duration
            startDataLocation = currentDataLocation - (width / self.lineWidth) / 2
            scalingFactor = 1
        } else {
            //TODO: 优化一些不会变的计算过程，固定为计算因数
            let range = displayTimeRange
            guard range != nil else {
                return
            }     
            let duration = audioDuration
            guard duration > 0 else {
                return
            }
            startDataLocation = range!.start * CGFloat(powerLevelArray.count) / duration
            let endDataLocation = range!.end * CGFloat(powerLevelArray.count) / duration
            scalingFactor = (endDataLocation - startDataLocation) / (width / lineWidth)
        }
        
        let startDataIndex = Int(startDataLocation)
        let displayLocationOffset = startDataLocation - CGFloat(startDataIndex)
        
        for lineIndex in 0 ..< Int(width / lineWidth) + 2 {
            let currentDataIndex = startDataIndex + Int(CGFloat(lineIndex) * scalingFactor)
            if currentDataIndex < 0 || currentDataIndex >= powerLevelArray.count {
                continue
            } else {
                //TODO: 给数组增加同步锁，防止越界、修改数组时访问数组导致崩溃
                let level = powerLevelArray[currentDataIndex]
                let x = (CGFloat(lineIndex) - displayLocationOffset) * lineWidth
                let lineHeight = CGFloat(level) * height / SMWaveformView.maxPowerLevel
                let startY = (height - lineHeight) / 2
                let endY = startY + lineHeight
                tempPath.move(to: CGPoint(x: x, y: startY))
                tempPath.addLine(to: CGPoint(x: x, y: endY))
            }
        }
    
        DispatchQueue.main.async {
            self.path = tempPath
            self.setNeedsDisplay()
        }
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
