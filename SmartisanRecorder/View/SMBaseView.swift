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

extension UIColor {
    convenience init(rgb256WithR: UInt8, g: UInt8, b: UInt8, alpha: CGFloat) {
        self.init(red: CGFloat(rgb256WithR) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }
}

extension CGFloat {
    func getTimeString(isNeedHour: Bool, isNeedMs: Bool) -> String {
        var leftTime = Int(self)
        var string = ""
        if isNeedHour {
            var hour = 0
            if leftTime >= 3600 {
                hour = leftTime / 3600
                leftTime %= 3600
            }
            string += String(format: "%02d:", hour)
        }
        let minute = leftTime / 60
        let second = leftTime % 60
        string += String(format: "%02d:%02d", minute, second)
        if isNeedMs {
            let ms = Int(self * 100) % 100
            string += String(format: ".%02d:", ms)
        }
        return string
    }
}
