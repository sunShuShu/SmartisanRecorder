//
//  SMLayer.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/3/12.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

protocol SMLayerDelegate: class {
    func drawSMLayer(in ctx: CGContext)
}

class SMLayer: CALayer, CALayerDelegate {
    weak var smLayerDelegate: SMLayerDelegate?
    
    init(delegate: SMLayerDelegate?) {
        super.init()
        self.smLayerDelegate = delegate
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        smLayerDelegate?.drawSMLayer(in: ctx)
    }
    
    func action(for layer: CALayer, forKey event: String) -> CAAction? {
        // No animation!
        return NSNull()
    }
}
