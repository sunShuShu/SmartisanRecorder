//
//  SMTimeElapseIndicatorView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class LocallyEffectiveButton: UIButton {
    var effectiveFrame: CGRect?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if hitView == self && effectiveFrame != nil {
                return effectiveFrame!.contains(point) ? self : nil
            } else {
                return hitView
            }
        }
        return nil
    }
}

class SMTimeElapseIndicator: SMBaseView {
    enum IndicatorType {
        case customLine
        case redLineWithAddButton
        case redLineWithMinusButton
    }
    
    private var editButton: LocallyEffectiveButton?
    var indicatorType: IndicatorType = .customLine {
        didSet {
            if indicatorType != .customLine && editButton == nil {
                editButton = LocallyEffectiveButton(type: .custom)
                editButton?.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                addSubview(editButton!)
            }
            
            switch indicatorType {
            case .customLine:
                editButton?.removeFromSuperview()
                editButton = nil
            case .redLineWithAddButton:
                editButton?.setBackgroundImage(#imageLiteral(resourceName: "flag_red_add.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .normal)
                editButton?.setBackgroundImage(#imageLiteral(resourceName: "flag_red_add_pressed.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .highlighted)
            case .redLineWithMinusButton:
                editButton?.setBackgroundImage(#imageLiteral(resourceName: "flag_red_delete.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .normal)
                editButton?.setBackgroundImage(#imageLiteral(resourceName: "flag_red_delete_pressed.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .highlighted)
            }
            setNeedsLayout()
        }
    }
    
    var buttonActionBlock: ((IndicatorType) -> ())?
    
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
    
    
    /// CGFloat: The position user touched, 0-1. Bool: drag is end.
    var indicatorDragged: ((CGFloat, Bool) -> ())?
    
    //MARK:-
    private var refreshTimer: CADisplayLink?
    private func setupTimer() {
        if isMovable && indicatorType != .customLine {
            assert(false, "The view can NOT be movable when it is't customLine type.")
            return
        }
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
    
    @objc private func buttonAction() {
        if let block = buttonActionBlock {
            block(indicatorType)
        }
    }
    
    //MARK:-
    private var lastTouchedPosition: CGPoint?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchesHandle(touches, isEnd: false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesHandle(touches, isEnd: false)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchedPosition = nil
        touchesHandle(touches, isEnd: true)
    }
    
    private func touchesHandle(_ touches: Set<UITouch>, isEnd: Bool) {
        if let draggedBlock = indicatorDragged {
            let touchedLocation = touches.first?.location(in: self)
            guard touchedLocation != lastTouchedPosition else {
                return
            }
            lastTouchedPosition = touchedLocation
            if let locationX = touchedLocation?.x {
                var location = locationX / width
                if location < 0 {
                    location = 0
                } else if location > 1 {
                    location = 1
                }
                draggedBlock(location, isEnd)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        if let button = editButton {
            //Make the button image be the center.
            let buttonWidth:CGFloat = 41.33
            UIView.autoLayout(button, top: 0, left: (width / 2 - 13.33), width: buttonWidth, height: height)
            button.effectiveFrame = CGRect(x: 0, y: 0, width: buttonWidth, height: 40)
        } else {
            refreshIndicator()
        }
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
    func setMovableLineParameter(updateCurrentPosition: (() -> (CGFloat))?, indicatorDragged: ((CGFloat, Bool) -> ())?) {
        self.isMovable = true
        self.updateCurrentPosition = updateCurrentPosition
        self.indicatorDragged = indicatorDragged
    }
    
    func setUnmovableLineParameter(currentPosition: CGFloat) {
        self.currentPosition = currentPosition
    }
    
    func setUnmovableAddButtonParameter(buttonActionBlock: @escaping (IndicatorType) -> ()) {
        self.indicatorType = .redLineWithAddButton
        self.buttonActionBlock = buttonActionBlock
    }
    
    func setUnmovableMinusButtonParameter(buttonActionBlock: @escaping (IndicatorType) -> ()) {
        self.indicatorType = .redLineWithMinusButton
        self.buttonActionBlock = buttonActionBlock
    }
}
