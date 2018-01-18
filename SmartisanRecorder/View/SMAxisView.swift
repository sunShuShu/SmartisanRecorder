//
//  File.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMAxisView: SMBaseView {
    var color = UIColor(rgb256WithR: 180, g: 180, b: 180, alpha: 1).cgColor
    var lineWidth: CGFloat = 0.8
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contex = UIGraphicsGetCurrentContext()
        guard contex != nil else {
            return
        }
        let path = CGMutablePath()
        let halfHeight = self.bounds.height / 2
        path.move(to: CGPoint(x: 0, y: halfHeight))
        path.addLine(to: CGPoint(x: self.bounds.width, y: halfHeight))
        contex!.addPath(path)
        contex!.setStrokeColor(color)
        contex!.setLineWidth(lineWidth)
        contex!.drawPath(using: .stroke)
    }
}
