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
    func drawRenderView(in ctx: CGContext)
}

class SMRenderView: UIView {
    weak var renderDelegate: RenderViewDelegate?
    
    init(delegate: RenderViewDelegate?) {
        super.init(frame: CGRect.zero)
        self.renderDelegate = delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            renderDelegate?.drawRenderView(in: context)
        }
    }
}
