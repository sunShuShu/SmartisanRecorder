//
//  SMBaseView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/4.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMBaseView: UIView {
    #if DEBUG
    lazy var measure = SMMeasure()
    #endif
    
    private(set) var width: CGFloat = 0
    private(set) var height: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        width = self.bounds.width
        height = self.bounds.height
    }
    
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
    
}

extension UIView {
    static func autoLayout(_ view: UIView, top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
        guard view.superview != nil else {
            assert(false, "(\(view)) has no super view!")
            return
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        let vflH = "H:|-left-[view]-right-|"
        let vflV = "V:|-top-[view]-bottom-|"
        let metrics = ["top": top, "bottom": bottom, "left": left, "right": right]
        let viewBind = ["view": view]
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vflH, options: [], metrics: metrics, views: viewBind))
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vflV, options: [], metrics: metrics, views: viewBind))
    }
    
    static func autoLayout(_ view: UIView, top: CGFloat = 0, left: CGFloat = 0, width: CGFloat, height: CGFloat) {
        guard view.superview != nil else {
            assert(false, "(\(view)) has no super view!")
            return
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        let vflH = "H:|-left-[view(width)]"
        let vflV = "V:|-top-[view(height)]"
        let metrics = ["top": top, "left": left, "width": width, "height": height]
        let viewBind = ["view": view]
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vflH, options: [], metrics: metrics, views: viewBind))
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vflV, options: [], metrics: metrics, views: viewBind))
    }
}

extension UIColor {
    convenience init(rgb256WithR: UInt8, g: UInt8, b: UInt8, alpha: CGFloat) {
        self.init(red: CGFloat(rgb256WithR) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }
}
