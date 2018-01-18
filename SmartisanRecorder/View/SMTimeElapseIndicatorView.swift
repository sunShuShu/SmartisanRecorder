//
//  SMTimeElapseIndicatorView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

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
