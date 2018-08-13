//
//  SMEditSoundView.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/18.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMEditSoundView: SMBaseView {
    static let editableSize = CGSize(width: 40, height: 40)
    let isIntegrated:Bool
    let extendWidth: CGFloat
    var audioDuration: SMTime
    
    lazy var leftEditor: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(x: -12, y: -22, width: 23, height: bounds.size.height + 22)
        layer.contents = UIImage(named: isIntegrated ? "window_editor_left.9" : "progressbar_editor_left")?.cgImage
        layer.contentsScale = 3;
        layer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
        self.layer.addSublayer(layer)
        return layer
    }()
//    lazy var rightEditor:CALayer = {
//        return
//    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _ = leftEditor
    }

    init(isIntegrated: Bool, extendWidth: CGFloat, audioDuration: SMTime) {
        self.isIntegrated = isIntegrated
        self.extendWidth = extendWidth
        self.audioDuration = audioDuration
        super.init(frame: CGRect())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
