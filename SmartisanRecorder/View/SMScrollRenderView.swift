//
//  SMScrollView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/23.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

typealias CanvasInfo = (canvas: SMRenderView, canvasOffset: CGFloat)
typealias CanvasPosition = (canvas: SMRenderView, positionX: CGFloat)

class SMScrollRenderView: SMBaseView {

    private let maxElementWidth: CGFloat
    
    /// Init. Don't create object with other init function.
    ///
    /// - Parameters:
    ///   - delegate: Render delegate, it will be invoked when the view need to be draw.
    ///   - maxElementWidth: If the parameter set to zero, the elements that are rendered to the canvas may be cut off.
    init(delegate: RenderViewDelegate, maxElementWidth: CGFloat) {
        self.maxElementWidth = maxElementWidth
        firstLayer = SMRenderView(delegate: delegate)
        secondLayer = SMRenderView(delegate: delegate)
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var rect = self.bounds
        rect.size.width += maxElementWidth
        firstLayer.frame = rect
        rect.origin.x = width
        secondLayer.frame = rect
        self.backgroundColor = superview?.backgroundColor ?? UIColor.clear
        if subviews.contains(firstLayer) != true {
            firstLayer.backgroundColor = backgroundColor ?? UIColor.clear
//            firstLayer.backgroundColor = UIColor.red
            addSubview(firstLayer)
        }
        if subviews.contains(secondLayer) != true {
            secondLayer.backgroundColor = backgroundColor ?? UIColor.clear
//            secondLayer.backgroundColor = UIColor.green
            addSubview(secondLayer)
        }
    }
    
    private var firstLayerOffset: CGFloat = 0
    private var firstLayer: SMRenderView
    private var secondLayer: SMRenderView
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
        
        @inline(__always) func resetPositionRenderFirstLayer() -> CanvasInfo {
            //Render the first layer and reset the layers position.
            firstLayerOffset = offset
            firstLayerX = 0
            isFirstLayerRendered = true
            isSecondLayerRendered = false
            return (canvas: firstLayer, canvasOffset: offset)
        }
        
        @inline(__always) func renderSecondLayer() -> CanvasInfo {
            isSecondLayerRendered = true
            return (canvas: secondLayer, canvasOffset: firstLayerOffset + width)
        }
        
        @inline(__always) func switchLayers() -> CanvasInfo {
            swap(&firstLayer, &secondLayer)
            firstLayerOffset += width
            firstLayerX = firstLayerOffset - offset
            return renderSecondLayer()
        }
        
        if isFirstLayerRendered == false {
            return resetPositionRenderFirstLayer()
        }
        
        if offset < firstLayerEndOffset && firstLayerEndOffset < endOffset {
            firstLayerX = firstLayerOffset - offset
            if isSecondLayerRendered == false {
                return renderSecondLayer()
            } else {
                return nil // Just move the layers.
            }
        } else {
            let renderedEndPositon = firstLayerEndOffset + width
            if offset < renderedEndPositon && renderedEndPositon < endOffset {
                return switchLayers()
            } else {
                return resetPositionRenderFirstLayer()
            }
        }
    }
    
    /// Get the canvas on the “offset” and the position on the canvas.
    ///
    /// - Parameter offset: offset
    /// - Returns: canvas and position
    func getCanvasPosition(with offset: CGFloat) -> [CanvasPosition] {
        var canvases = [CanvasPosition]()
        let positionX = offset - firstLayerOffset
        if positionX > width {
            canvases.append((canvas: secondLayer, positionX: positionX - width))
        }
        if positionX < width + maxElementWidth {
            canvases.append((canvas: firstLayer, positionX: positionX))
        }
        return canvases
    }
}
