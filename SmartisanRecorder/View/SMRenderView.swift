//
//  SMLayer.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/3/12.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

protocol RenderViewDelegate: class {
    
    /// If the “path” parameter has been set, there is no need to set path to the CGContext in this function.
    ///
    /// - Parameter ctx: context
    func drawRenderView(in ctx: CGContext)
}

class SMRenderView: SMBaseView {
    private var needsClear = false
    func setNeedsClear() {
        DispatchQueue.main.async {
            self.needsClear = true
            self.setNeedsDisplay()
        }
    }
    
    private weak var renderDelegate: RenderViewDelegate?
    
    init(delegate: RenderViewDelegate?) {
        super.init(frame: CGRect.zero)
        self.renderDelegate = delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// The path will be set to CGContext of the SMRenderView. 
    var path: CGPath?
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            if needsClear {
                SMLog("SMRenderView: clear()")
                needsClear = false
                return
            }
            if let path = self.path {
                context.addPath(path)
            }
            renderDelegate?.drawRenderView(in: context)
        }
    }
}
