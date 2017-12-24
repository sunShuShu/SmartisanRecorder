//
//  SMWaveformView.swift
//  SmartisanRecorder
//
//  Created by sunda on 08/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class SMWaveformView: UIView {
    static var maxPowerLevel = CGFloat(UInt8.max)
    /// line width(point) e.g. 1 point = 2 pixels in iPhone7, 1 point = 3 pixels in plus series
    var lineWidth: CGFloat = 1
    /// line color
    var color: CGColor = UIColor.black.cgColor
    /// line height(point)
    private var path = CGMutablePath()
    var powerLevel: [UInt8] = Array() {
        didSet {
            self.path = CGMutablePath()
            for (index, oneLevel) in powerLevel.enumerated() {
                let height = (CGFloat(oneLevel) * bounds.height) / CGFloat(SMWaveformView.maxPowerLevel)
                let x = CGFloat(index) * lineWidth
                let startY = (self.bounds.height - height) / 2
                let endY = startY + height
                path.move(to: CGPoint(x: x, y: startY))
                path.addLine(to: CGPoint(x: x, y: endY))
            }
            
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }

        contex!.addPath(path)
        contex!.setStrokeColor(color)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}
