//
//  SMScrollView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/23.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

protocol ScrollRenderDelegate: class {
    func drawToScrollRenderView(in context: CGContext)
}

typealias ScrollRenderInfo = (canvas: UIView, offset: CGFloat, lineX:  CGFloat?)

class SMScrollRenderView: SMBaseView {
    weak var renderDelegate: ScrollRenderDelegate?

    var isRecordingMode = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        SMLog("\(self) \n layoutSubviews...")
        var rect = self.bounds
        firstLayer.frame = rect
        rect.origin.x = width
        secondLayer.frame = rect
        self.backgroundColor = superview?.backgroundColor
        firstLayer.backgroundColor = UIColor.red
        secondLayer.backgroundColor = UIColor.green
    }
    
    private var renderedPosition: CGFloat = 0
    private lazy var firstLayer: UIView = {
        return self.addNewView()
    }()
    private lazy var secondLayer: UIView = {
        return self.addNewView()
    }()
    
    private func addNewView() -> UIView {
        let newView = UIView()
        newView.translatesAutoresizingMaskIntoConstraints = true
        self.addSubview(newView)
        return newView
    }
    
    func setOffset(_ offset: CGFloat) -> ScrollRenderInfo? {
        let width = self.width
        var firstLayerX: CGFloat = 0
        var renderLayer: UIView? = nil
        
        let renderedMidPosition = renderedPosition + width
        let endOffset = offset + width;
        if offset <= renderedMidPosition && renderedMidPosition <= endOffset {
            //Just move the rendered waveform if the display range in the rendered range.
            SMLog("Just move the waveform.");
            firstLayerX = renderedPosition - offset
        } else {
            let renderedEndPositon = renderedMidPosition + width
            if offset <= renderedEndPositon && renderedEndPositon <= endOffset {
                //Move the rendered view and switch the layers. render the secondLayer.
                SMLog("Move waveform + switch layers + render the secondLayer.");
                swap(&firstLayer, &secondLayer)
                renderedPosition += width
                renderLayer = secondLayer
                firstLayerX = renderedPosition - offset
            } else {
                //Render two the layers and reset the layers position.
                SMLog("Render the layers + reset the layers position.")
                renderedPosition = offset
                renderLayer = firstLayer
                firstLayerX = 0
            }
        }
        
        let secondLayerX = firstLayerX + width
        DispatchQueue.main.async {
            // Move the layers
            self.firstLayer.frame.origin.x = firstLayerX
            self.secondLayer.frame.origin.x = secondLayerX
        }
        
        if isRecordingMode {
            //TODO: 优化计算常量
            //render when set a new offset
            let halfWidth = width / 2
            let toRenderLineX: CGFloat
            let toRenderOffset = offset + halfWidth
            if secondLayerX >= halfWidth {
                renderLayer = firstLayer
                toRenderLineX = firstLayerX + halfWidth
            } else {
                renderLayer = secondLayer
                toRenderLineX = halfWidth - secondLayerX
            }
            return (canvas: renderLayer!, offset: toRenderOffset, lineX: toRenderLineX)
        } else if let tempLayer = renderLayer {
            //render when needed
            return (canvas: tempLayer, offset: renderedPosition, lineX: nil)
        } else {
            //no need to render
            return nil
        }
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        SMLog("ScrollRenderView...draw")
        super.draw(layer, in: ctx)
        if let renderDelegate = self.renderDelegate {
            renderDelegate.drawToScrollRenderView(in: ctx)
        }
    }
//    override func draw(_ rect: CGRect) {
//        SMLog("ScrollRenderView...draw")
//        super.draw(rect)
//        if let contex = UIGraphicsGetCurrentContext() {
//            if let renderDelegate = self.renderDelegate {
//                renderDelegate.drawToScrollRenderView(in: contex)
//            }
//        }
//    }
}

extension SMScrollRenderView {
//    setIsRecordMode<T: ScrollRenderDelegate>(_ mode: Bool, renderDelegate: T) {
//
//    }
}
