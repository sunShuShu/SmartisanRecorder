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
    enum EditButtonStyle {
        case none
        case add
        case minus
    }
    
    private static let editButtonSize: CGFloat = 40
    
    var editButtonStyle: EditButtonStyle = .none {
        didSet {
            if editButtonStyle != .none && editButton == nil {
                editButton = UIButton(type: .custom)
                editButton!.backgroundColor = UIColor.gray
                addSubview(editButton!)
            }
            
            switch editButtonStyle {
            case .none:
                editButton?.removeFromSuperview()
                editButton = nil
            case .add:
                editButton?.setImage(#imageLiteral(resourceName: "flag_red_add.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .normal)
                editButton?.setImage(#imageLiteral(resourceName: "flag_red_add_pressed.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .highlighted)
            case .minus:
                editButton?.setImage(#imageLiteral(resourceName: "flag_red_delete.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .normal)
                editButton?.setImage(#imageLiteral(resourceName: "flag_red_delete_pressed.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50), for: .highlighted)
            }
            editButton?.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let button = editButton {
            UIView.autoLayout(button, top: 0, left: width / 2, width: 41.33, height: SMFlagView.editButtonSize)
        }
    }
    
    private(set) var editButton: UIButton?
    private let renderQueue = DispatchQueue(label: "com.sunshushu.TimeScaleRender", qos: .userInteractive)
    
    func setCurrentTime(_ time: SMTime) {
        
    }
}
