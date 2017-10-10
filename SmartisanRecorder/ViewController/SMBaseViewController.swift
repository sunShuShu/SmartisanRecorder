//
//  SMBaseViewController.swift
//  SmartisanRecorder
//
//  Created by sunda on 25/08/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation

class SMBaseViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("\(type(of: self))");
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
         MobClick.endLogPageView("\(type(of: self))");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SMLog("Memory warning!", level: .high)
    }
}
