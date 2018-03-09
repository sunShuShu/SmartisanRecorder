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
    func renderView(in range: ClosedRange<CGFloat>, context: CGContext)
    
    /// For recording mode.
    ///
    /// - Parameters:
    ///   - offset: offset of scroll render view center
    ///   - contextX: x position of drawing line in context
    ///   - context: to draw in the context
    func renderALineOfWaveform(in offset: CGFloat, contextX: CGFloat, context: CGContext)
}

class SMScrollRenderView: SMBaseView {
    
    weak var renderDelegate: ScrollRenderDelegate?
    /// If the value is true "renderRecordingContent" will be invoke, or "renderView" will be
    var isRecordingMode = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
    
    private var toRenderRange: ClosedRange<CGFloat>? = nil // For playing audio file
    private var toRenderOffset: CGFloat? = nil // For recording mode
    private var toRenderContextX: CGFloat? = nil
    
    func setOffset(_ offset: CGFloat) {
        let width = self.width
        var firstLayerX: CGFloat = 0
        var renderLayer: UIView? = nil
        
        let renderedMidPosition = renderedPosition + width
        let endOffset = offset + width;
        if (offset <= renderedMidPosition && renderedMidPosition <= endOffset) {
            //Just move the rendered waveform if the display range in the rendered range.
            SMLog("Just move the waveform.");
            firstLayerX = renderedPosition - offset
        } else {
            let renderedEndPositon = renderedMidPosition + width
            if (offset <= renderedEndPositon && renderedEndPositon <= endOffset) {
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
        
        if (isRecordingMode) {
            //TODO: 优化计算常量
            let halfWidth = width / 2
            toRenderOffset = offset + halfWidth
            if (secondLayerX >= halfWidth) {
                renderLayer = firstLayer
                toRenderContextX = firstLayerX + halfWidth
            } else {
                renderLayer = secondLayer
                toRenderContextX = halfWidth - secondLayerX
            }
        }
        
        DispatchQueue.main.async {
            self.firstLayer.frame.origin.x = firstLayerX
            self.secondLayer.frame.origin.x = secondLayerX
            if let drawLayer = renderLayer {
                drawLayer.setNeedsDisplay()
                renderLayer = nil
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        SMLog("Render...draw")
        //TODO: 是否每次移动view都会调用此方法，如果是则判断是否需要渲染，如果不是则可以直接渲染
        if let renderDelegate = self.renderDelegate {
            if let contex = UIGraphicsGetCurrentContext() {
                if let location = toRenderOffset {
                    renderDelegate.renderALineOfWaveform(in: location, contextX: toRenderContextX!, context: contex)
                    toRenderOffset = nil
                }
                if let range = toRenderRange {
                    renderDelegate.renderView(in: range, context: contex)
                    toRenderRange = nil
                }
            }
        }
    }
}

extension SMScrollRenderView {
//    setIsRecordMode<T: ScrollRenderDelegate>(_ mode: Bool, renderDelegate: T) {
//    
//    }
}
