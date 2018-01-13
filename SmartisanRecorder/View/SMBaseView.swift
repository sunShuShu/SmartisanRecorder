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
    
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
}
