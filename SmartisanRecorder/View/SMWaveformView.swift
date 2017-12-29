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
    
    private var renderTimer: CADisplayLink?
    private var renderQueue: DispatchQueue?
    private var renderTimerNeedRemoved = true
    
    /// The waveform view has two kind of way to update display. If isDynamic is true, the updatePlayedTime will be call when it's time to render screen. If isDymanic is false, waveform view will be render when the updateDisplayRange changed.
    @objc var isDynamic = false {
        didSet {
            guard isDynamic != oldValue else {
                return
            }
            if renderTimer == nil {
                renderTimer = CADisplayLink(target: self, selector: #selector(render))
                renderQueue = DispatchQueue(label: "com.sunshushu.WaveformRenderQueue", qos: .userInteractive)
                renderTimerNeedRemoved = false
                renderQueue?.async {
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
    }

    /// The block need to return current played time. Block execution time can NOT exceed 1/60 second. The shorter the block executes, the better, and don't make time-consuming operations inside.
    var updatePlayedTime: (() -> (CGFloat))?
    var updateDisplayRange: (CGFloat, CGFloat)? {
        willSet {
            
        }
    }
    var audioDuration: CGFloat = 0
    
    private var path = CGMutablePath()
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
    
    //MARK:-
    @objc func render() {
        //Stop and remove render timer in render queue.
        guard renderTimerNeedRemoved == false else {
            renderTimer?.isPaused = true
            renderTimer?.invalidate()
            renderTimer?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            return
        }
        if let block = updatePlayedTime {
            let currentTime = block()
            SMLog("\(currentTime)")
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
