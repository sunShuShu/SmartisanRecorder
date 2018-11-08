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
    static let timeLabelSize = CGSize(width: 57, height: 30)
    let isIntegrated: Bool
    let extendWidth: CGFloat
    var audioDuration: SMTime
    private var editorRect = CGRect.zero
    
    lazy var leftEditorLayer: CALayer = {
        let layer = CALayer()
        layer.frame = editorRect
        layer.contents = UIImage(named: isIntegrated ? "window_editor_left.9" : "progressbar_editor_left")?.cgImage
        layer.contentsScale = 3;
        layer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
        return layer
    }()
    lazy var rightEditorLayer: CALayer = {
        let layer = CALayer()
        layer.frame = editorRect
        layer.frame.origin.x += bounds.size.width
        layer.contents = UIImage(named: isIntegrated ? "window_editor_right.9" : "progressbar_editor_right")?.cgImage
        layer.contentsScale = 3;
        layer.contentsCenter = CGRect(x: 0, y: 0.5, width: 0, height: 0)
        return layer
    }()
    lazy var selectedZoneLayer: CALayer = {
        let layer = CALayer()
        layer.frame = self.bounds
        layer.backgroundColor = UIColor(rgb256WithR: 92, g: 133, b: 229, alpha: 0.1).cgColor;
        return layer;
    }()
    
    lazy var leftTimeLabel: UILabel = {
        let label = UILabel()
        label.text = SMTime(0).toShortString()
        label.frame = CGRect(origin: CGPoint.zero, size: SMEditSoundView.timeLabelSize)
        return label
    }()
    lazy var rightTimeLabel: UILabel = {
        let label = UILabel()
        label.text = self.audioDuration.toShortString()
        let origin = CGPoint(x: bounds.width - SMEditSoundView.timeLabelSize.width, y: 0)
        label.frame = CGRect(origin: origin, size: SMEditSoundView.timeLabelSize)
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isIntegrated {
            self.editorRect = CGRect(x: -12, y: -22, width: 23, height: 44 + bounds.size.height)
        } else {
            self.editorRect = CGRect(x: -6.66, y: -13, width: 13, height: 26 + bounds.size.height)
        }
        
        self.layer.addSublayer(selectedZoneLayer)
        self.layer.addSublayer(leftEditorLayer)
        self.layer.addSublayer(rightEditorLayer)
        self.addSubview(leftTimeLabel)
        self.addSubview(rightTimeLabel)
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
