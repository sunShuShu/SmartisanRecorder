//
//  SMFlagView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMFlagView: SMBaseView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    private let renderQueue = DispatchQueue(label: "com.sunshushu.TimeScaleRender", qos: .userInteractive)
    
    func setCurrentTime(_ time: SMTime) {
        
    }
}
