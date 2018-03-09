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
    
    /// For playing audio file.
    ///
    /// - Parameters:
    ///   - range: rander range
    ///   - context: to draw in the context
    func renderView(_ view: UIView, in range: ClosedRange<CGFloat>)
    
    /// For recording mode.
    ///
    /// - Parameters:
    ///   - offset: offset of scroll render view center
    ///   - contextX: x position of drawing line in context
    ///   - context: to draw in the context
    func renderALineOfWaveform(in view: UIView, offset: CGFloat, lineX: CGFloat)
    
    func drawToScrollRenderView(in context: CGContext)
}

class SMScrollRenderView: SMBaseView {
    
    weak var renderDelegate: ScrollRenderDelegate?
    /// If the value is true "renderRecordingContent" will be invoke, or "renderView" will be
    var isRecordingMode = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        SMLog("\(self) \n layoutSubviews...")
        var rect = self.bounds
        firstLayer.frame = rect
        rect.origin.x = width
        secondLayer.frame = rect
        
        firstLayer.backgroundColor = UIColor.green
        secondLayer.backgroundColor = UIColor.red
    }
    
    private var renderedPosition: CGFloat = 0
    private lazy var firstLayer = UIView()
    private lazy var secondLayer = UIView()
    
//    private var toRenderRange: ClosedRange<CGFloat>? = nil // For playing audio file
//    private var toRenderOffset: CGFloat? = nil // For recording mode
//    private var toRenderContextX: CGFloat? = nil
    
    func setOffset(_ offset: CGFloat) {
        let width = self.width
        var firstLayerX: CGFloat = 0
        var renderLayer: UIView? = nil
        var toRenderRange: ClosedRange<CGFloat>? = nil // For playing audio file
        
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
                toRenderRange = renderedPosition...(renderedPosition + width)
                renderLayer = secondLayer
                firstLayerX = renderedPosition - offset
            } else {
                //Render two the layers and reset the layers position.
                SMLog("Render the layers + reset the layers position.")
                renderedPosition = offset
                toRenderRange = renderedPosition...(renderedPosition + width)
                renderLayer = firstLayer
                firstLayerX = 0
            }
        }
        
        let secondLayerX = firstLayerX + width
        
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
            
            if let renderDelegate = self.renderDelegate {
                renderDelegate.renderALineOfWaveform(in: renderLayer!, offset: toRenderOffset, lineX: toRenderLineX)
            }
        } else if let tempLayer = renderLayer {
            //render when needed
            if let renderDelegate = self.renderDelegate {
                renderDelegate.renderView(tempLayer, in: toRenderRange!)
            }
        }
        
        // Move the layers
        DispatchQueue.main.async {
            self.firstLayer.frame.origin.x = firstLayerX
            self.secondLayer.frame.origin.x = secondLayerX
        }
    }
    
    override func draw(_ rect: CGRect) {
        SMLog("ScrollRenderView...draw")
        super.draw(rect)
        if let contex = UIGraphicsGetCurrentContext() {
            if let renderDelegate = self.renderDelegate {
                renderDelegate.drawToScrollRenderView(in: contex)
            }
        }
    }
}

extension SMScrollRenderView {
//    setIsRecordMode<T: ScrollRenderDelegate>(_ mode: Bool, renderDelegate: T) {
//
//    }
}
