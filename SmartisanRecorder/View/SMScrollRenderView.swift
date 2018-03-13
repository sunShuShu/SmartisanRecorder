//
//  SMScrollView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/23.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

//typealias ScrollRenderInfo = (canvas: CALayer, canvasOffset: CGFloat, lineX:  CGFloat?)
typealias CanvasInfo = (canvas: CALayer, canvasOffset: CGFloat)
typealias CanvasPosition = (canvas: CALayer, positionX: CGFloat)

class SMScrollRenderView: SMBaseView {

    init(delegate: SMLayerDelegate) {
        firstLayer = SMLayer(delegate: delegate)
        secondLayer = SMLayer(delegate: delegate)
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var rect = self.bounds
        firstLayer.frame = rect
        rect.origin.x = width
        secondLayer.frame = rect
        self.backgroundColor = superview?.backgroundColor
        if layer.sublayers?.contains(firstLayer) != true {
            layer.addSublayer(firstLayer)
        }
        if layer.sublayers?.contains(secondLayer) != true {
            layer.addSublayer(secondLayer)
        }
    }
    
    private var firstLayerOffset: CGFloat = 0
    private var firstLayer: SMLayer
    private var secondLayer: SMLayer
    private var isFirstLayerRendered = false
    private var isSecondLayerRendered = false
    
    func setOffset(_ offset: CGFloat) -> CanvasInfo? {
        let width = self.width
        let firstLayerEndOffset = firstLayerOffset + width
        let endOffset = offset + width;
        
        var firstLayerX: CGFloat = 0
        
        defer {
            // Move the layers
            let secondLayerX = firstLayerX + width
            DispatchQueue.main.async {
                self.firstLayer.frame.origin.x = firstLayerX
                self.secondLayer.frame.origin.x = secondLayerX
            }
        }
        
        if offset < firstLayerEndOffset && firstLayerEndOffset < endOffset &&
            isFirstLayerRendered {
            firstLayerX = firstLayerOffset - offset
            if isSecondLayerRendered {
                //Just move the rendered waveform if the display range in the rendered range.
                return nil
            } else {
                isSecondLayerRendered = true
                return (canvas: secondLayer, canvasOffset: firstLayerOffset + width)
            }
        } else {
            let renderedEndPositon = firstLayerEndOffset + width
            if offset <= renderedEndPositon && renderedEndPositon <= endOffset &&
                isFirstLayerRendered {
                //Move the rendered view and switch the layers. render the secondLayer.
                SMLog("Move waveform + switch layers + render the secondLayer.");
                swap(&firstLayer, &secondLayer)
                firstLayerOffset += width
                firstLayerX = firstLayerOffset - offset
                return (canvas: secondLayer, canvasOffset: firstLayerOffset + width)
            } else {
                //Render the first layer and reset the layers position.
                SMLog("Render the first layer + reset the layers position.")
                firstLayerOffset = offset
                firstLayerX = 0
                isFirstLayerRendered = true
                isSecondLayerRendered = false
                return (canvas: firstLayer, canvasOffset: offset)
            }
        }
    }
    
    func getCanvasPosition(with offset: CGFloat) -> CanvasPosition {
        let positionX = offset - firstLayerOffset
        if positionX > width {
            return (canvas: secondLayer, positionX: positionX - width)
        } else {
            return (canvas: firstLayer, positionX: positionX)
        }
    }
}
