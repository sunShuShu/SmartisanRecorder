//
//  SMTimeScaleView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMTimeScaleView: SMBaseView, RenderViewDelegate {
    var widthPerSecond: CGFloat = 50 {
        didSet {
            if widthPerSecond <= 0 {
                assert(false, "widthPerSecond can not be less than or equle 0!")
                widthPerSecond = oldValue
            }
        }
    }
    var lineWidth: CGFloat = 0.5
    var middleScaleHight: CGFloat = 1
    var lineColor: CGColor = UIColor(rgb256WithR: 183, g: 183, b: 183, alpha: 1).cgColor
    var timeColor: UIColor = UIColor(rgb256WithR: 130, g: 130, b: 130, alpha: 1)
    var timeStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        return style
    }()
    
    //MARK:-
    private var halfLineWidth: CGFloat = 0
    private var halfWidthPerSecond:CGFloat = 0
    private var labelCount = 0
    private var bottomLineStart = CGPoint.zero
    private var bottomLineEnd = CGPoint.zero
    private var shortScaleLineStartY: CGFloat = 0
    private var shortScaleLineEndY: CGFloat = 0
    private var timeRect = CGRect.zero
    private var timeAttributes: [NSAttributedStringKey:Any]?
    
    //MARK:-
    private lazy var scrollRenderView = {
        return SMScrollRenderView(delegate: self, maxElementWidth: widthPerSecond);
    }()
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = superview?.backgroundColor ?? UIColor.clear
        self.addSubview(scrollRenderView)
        UIView.autoLayout(scrollRenderView)
        
        halfLineWidth = lineWidth / 2
        timeIndicatorOffset = width / widthPerSecond / 2
        halfWidthPerSecond = widthPerSecond / 2
        labelCount = Int(width / widthPerSecond + 2)
        bottomLineStart = CGPoint(x: 0, y: height - halfLineWidth)
        bottomLineEnd = CGPoint(x: width, y: height - halfLineWidth)
        shortScaleLineStartY = height - lineWidth
        shortScaleLineEndY = shortScaleLineStartY - middleScaleHight
        let maxTimeHeight = height - middleScaleHight * 2
        let fontSize = maxTimeHeight * 0.77
        let timeFont = UIFont(name: "Helvetica", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        timeAttributes = [NSAttributedStringKey.font:timeFont, NSAttributedStringKey.foregroundColor:timeColor, NSAttributedStringKey.paragraphStyle:timeStyle]
        let stringSize = ("0:0" as NSString).size(withAttributes: timeAttributes)
        timeRect.origin.y = (maxTimeHeight - stringSize.height) / 2
        timeRect.size.height = stringSize.height
        timeRect.size.width = widthPerSecond
    }
    
    private let timeTool = SMTimeTool()
    private let renderQueue = DispatchQueue(label: "com.sunshushu.TimeScaleRender", qos: .userInteractive)
    private var timeIndicatorOffset: CGFloat = 0
    private lazy var path = CGMutablePath()
    private lazy var timeLabelInfo = [(str: String, x: CGFloat)]()
    
    func setCurrentTime(_ currentTime: SMTime) {
        renderQueue.async {
            [weak self] in
            if let strongSelf = self {
                strongSelf.measure.start()
                
                let tempPath = CGMutablePath()
                var tempTimeLabelInfo = [(String, CGFloat)]()
                
                let offset = strongSelf.widthPerSecond * (currentTime - strongSelf.timeIndicatorOffset);
                let canvasInfo = strongSelf.scrollRenderView.setOffset(offset)
                if canvasInfo == nil {
                    // Do not need to render
                    return
                }
                defer {
                    DispatchQueue.main.async {
                        strongSelf.path = tempPath
                        strongSelf.timeLabelInfo = tempTimeLabelInfo
                        canvasInfo!.canvas.setNeedsDisplay()
                    }
                }
                
                tempPath.move(to: strongSelf.bottomLineStart)
                tempPath.addLine(to: strongSelf.bottomLineEnd)
                
                let startTime = canvasInfo!.canvasOffset / strongSelf.widthPerSecond
                let labelOffset = startTime.truncatingRemainder(dividingBy: 1) * strongSelf.widthPerSecond
                for index in 0..<strongSelf.labelCount {
                    let currentLabelTime = index + Int(startTime)
                    if currentLabelTime < 0 {
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
                        let timeString = strongSelf.timeTool.secondToString(time: SMTime(currentLabelTime) + 0.5, isNeedHour: true, isNeedMs: false)
                        tempTimeLabelInfo.append((timeString, x))
                    }
                }
                strongSelf.measure.end()
            }
        }
    }
    
    deinit {
        measure.getReport(from: self)
    }
    
    func drawRenderView(in ctx: CGContext) {
        for (string, x) in timeLabelInfo {
            timeRect.origin.x = x
            string.draw(in: timeRect, withAttributes: timeAttributes)
        }
        ctx.addPath(path)
        ctx.setStrokeColor(lineColor)
        ctx.setLineWidth(lineWidth)
        ctx.drawPath(using: .stroke)
    }
}
