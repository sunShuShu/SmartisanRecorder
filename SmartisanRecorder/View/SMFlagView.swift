//
//  SMFlagView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMFlagView: SMBaseView, RenderViewDelegate {
    static let maxFlagsCount = 99
    static let flagWidth: CGFloat = 15.33
    
    var widthPerSecond: CGFloat = 50 {
        didSet {
            if widthPerSecond <= 0 {
                assert(false, "widthPerSecond can not be less than or equle 0!")
                widthPerSecond = oldValue
            }
        }
    }
    
    var flagModel: SMFlagModel?
    
    private let renderQueue = DispatchQueue(label: "com.sunshushu.FlagRender", qos: .userInteractive)
    private lazy var scrollRenderView = {
        return SMScrollRenderView(delegate: self, maxElementWidth: SMFlagView.flagWidth);
    }()
    
    // MARK:- cache
    private var halfDisplayTime: CGFloat = 0
    private var displayTimeLength: CGFloat = 0
    private var timeIndicatorOffset: CGFloat = 0
    private var numRect = CGRect()
    private var flagRect = CGRect()
    private lazy var flagImage = UIImage(named: "main_flag.9")!.cgImage!
    override func layoutSubviews() {
        super.layoutSubviews()
        displayTimeLength = width / widthPerSecond
        halfDisplayTime = displayTimeLength / 2
        numRect = CGRect(x: 0, y: 0, width: SMFlagView.flagWidth, height: 13.33)
        flagRect = CGRect(x: 0, y: 0, width: SMFlagView.flagWidth, height: height)
        addSubview(scrollRenderView)
        UIView.autoLayout(scrollRenderView)
    }
    
    deinit {
        measure.getReport(from: self)
    }
    
    //MARK:- render
    typealias FlagRenderInfo = (position: CGFloat, image: UIImage)
    
    //TODO: add displaying flags of a range of time
    func setCurrentTime(_ currentTime: SMTime) {
        let flagModel = self.flagModel
        if flagModel == nil || flagModel!.locations.count <= 0 {
            return;
        }
        
        renderQueue.async {
            [weak self] in
            self?.measure.start()
            defer{
                self?.measure.end()
            }
            
            if let strongSelf = self {
                let offset = strongSelf.widthPerSecond * (currentTime - strongSelf.timeIndicatorOffset);
                let canvasInfo = strongSelf.scrollRenderView.setOffset(offset)
                if canvasInfo == nil {
                    // Do not need to render
                    return
                }
                
                var startRenderTime = canvasInfo!.canvasOffset / strongSelf.widthPerSecond
                startRenderTime -= strongSelf.halfDisplayTime
                let endRenderTime =  startRenderTime + strongSelf.displayTimeLength
                let subRange = flagModel!.subRange(startTime: startRenderTime, endTime: endRenderTime)
                var imageToRender = [FlagRenderInfo]()
                for (index, time) in subRange {
                    SMLog("index:\(index), time:\(time)")
                    let numImageName = String(format: "flag_num_%02d", index + 1)
                    if let numImage = UIImage(named: numImageName) {
                        let x = (time - startRenderTime) * strongSelf.widthPerSecond
                        imageToRender.append((x, numImage))
                    }
                }
                canvasInfo?.canvas.externalData = imageToRender;
                
                DispatchQueue.main.async {
                    canvasInfo!.canvas.setNeedsDisplay()
                }
            }
            
        }
    }
    
    func drawRenderView(view: SMRenderView, in ctx: CGContext) {
        DispatchQueue.main.async {
            if let layers = view.layer.sublayers {
                for layer in layers {
                    layer.removeFromSuperlayer()
                }
            }
            
            if let imageToRender = view.externalData as? [FlagRenderInfo] {
                for (x, image) in imageToRender {
                    let flagLayer = CALayer()
                    self.flagRect.origin.x = x
                    flagLayer.frame = self.flagRect
                    flagLayer.contents = self.flagImage
                    flagLayer.contentsScale = 3
                    flagLayer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
                    view.layer.addSublayer(flagLayer)
                    let numLayer = CALayer()
                    self.numRect.origin.x = x
                    numLayer.frame = self.numRect
                    numLayer.contents = image.cgImage
                    view.layer.addSublayer(numLayer)
                }
            }
        }
    }
}

extension SMFlagView {
    func setflagModel(_ model: SMFlagModel?) {
        self.flagModel = model
    }
}
