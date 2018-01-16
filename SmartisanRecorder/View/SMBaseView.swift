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
