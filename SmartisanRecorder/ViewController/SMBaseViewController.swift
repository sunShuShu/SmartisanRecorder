//
//  SMBaseViewController.swift
//  SmartisanRecorder
//
//  Created by sunda on 25/08/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMBaseViewController: UIViewController {
    #if DEBUG
    lazy var measure = SMMeasure()
    #endif
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SMLog("Memory warning!", level: .high)
    }
    
    deinit {
        SMLog("\(type(of: self)) RELEASE!")
    }
}
