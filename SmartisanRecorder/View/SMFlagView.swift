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
    
    var widthPerSecond: CGFloat = 50 {
        didSet {
            if widthPerSecond <= 0 {
                assert(false, "widthPerSecond can not be less than or equle 0!")
                widthPerSecond = oldValue
            }
        }
    }
    
    private lazy var flagsTimeArray = [SMTime]()
    func setFlagsTimeArray(_ array: [SMTime]) {
        objc_sync_enter(self)
        flagsTimeArray = array
        objc_sync_exit(self)
    }
    
    private var timeIndicatorOffset: SMTime = 0
    private lazy var flagRect = CGRect(x: 0, y: 0, width: 15.33, height: height)
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    deinit {
        measure.getReport(from: self)
    }
    
    private let renderQueue = DispatchQueue(label: "com.sunshushu.FlagRender", qos: .userInteractive)
    func setCurrentTime(_ currentTime: SMTime) {
        guard flagsTimeArray.count > 0 else {
            return
        }
        
        renderQueue.async {
            [weak self] in
            if let strongSelf = self {
                strongSelf.measure.start()
                
                let displayTimeLength = strongSelf.width / strongSelf.widthPerSecond
                let startTime = currentTime - displayTimeLength / 2
                let endTime = startTime + displayTimeLength
                
                var needMoveViews = [UIView: CGRect]()
                var needAddViews = [UIView]()
                
                if let range = strongSelf.flagsTimeArray.binarySearch(from: startTime, to: endTime) {
                    for index in range.startIndex...range.endIndex {
                        let flagTime = strongSelf.flagsTimeArray[index]
                        let x = (flagTime - startTime) * strongSelf.widthPerSecond
                        var rect = strongSelf.flagRect
                        rect.origin.x = x
                        if let subView = strongSelf.viewWithTag(index + 1) {
                            //Move the flag view if the flag is exist
                            needMoveViews.updateValue(rect, forKey: subView)
                        } else {
                            //Add the new flag view
                            let imageView = UIImageView(image: #imageLiteral(resourceName: "main_flag.9").stretchableImage(withLeftCapWidth: 0, topCapHeight: 50))
                            imageView.tag = index + 1
                            imageView.frame = rect
                            needAddViews.append(imageView)
                        }
                    }
                } else {
                    return
                }
                
                DispatchQueue.main.async {
                    for view in strongSelf.subviews {
                        if needMoveViews.keys.contains(view) == false {
                            view.removeFromSuperview()
                        }
                    }
                    for view in needAddViews {
                        strongSelf.addSubview(view)
                    }
                    for (view, frame) in needMoveViews {
                        view.frame = frame
                    }
                }
                strongSelf.measure.end()
            }
        }
    }
}
