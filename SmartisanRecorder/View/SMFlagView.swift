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
    static let maxFlagsCount = 99
    
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
    private let renderQueue = DispatchQueue(label: "com.sunshushu.WaveformRender", qos: .userInteractive)
    override func layoutSubviews() {
        super.layoutSubviews()
        halfDisplayTime = displayTimeLength / 2
        displayTimeLength = width / widthPerSecond
    }
    
    deinit {
        measure.getReport(from: self)
    }
    
    //MARK:-
    private var halfDisplayTime: CGFloat = 0
    private var displayTimeLength: CGFloat = 0
    
    private var cacheDataTimeRange: ClosedRange<CGFloat> = 0...0
    private var cacheDataIndexRange: CountableClosedRange<Int>?
    private var displayingImages = [Int: UIImage]()
    func setCurrentTime(_ currentTime: SMTime) {
        guard flagsTimeArray.count > 0 else {
            return
        }
        
        renderQueue.async {
            self.measure.start()
            
            let startTime = currentTime - self.halfDisplayTime
            let endTime = startTime + self.displayTimeLength
            let dataRange: CountableClosedRange<Int>?
            if self.cacheDataTimeRange.contains(startTime) && self.cacheDataTimeRange.contains(endTime) {
                dataRange = self.cacheDataIndexRange
            } else {
                //Additional cache 3 seconds data.
                let cacheEndTime = endTime + 3
                dataRange = self.flagsTimeArray.binarySearch(from: startTime, to: cacheEndTime)
                self.cacheDataTimeRange = startTime...cacheEndTime
                self.cacheDataIndexRange = dataRange
            }
            
            //Remove flag views.
            var needRemovedViewsTag: [Int]?
            for (index, _) in self.displayingImages {
                if dataRange == nil || dataRange!.contains(index) == false {
                    if needRemovedViewsTag == nil {
                        needRemovedViewsTag = [Int]()
                    }
                    needRemovedViewsTag!.append(index)
                    self.displayingImages.removeValue(forKey: index)
                }
            }
            
            var needMoveViews = [Int: CGRect]()
            var needAddViews: [Int: (UIImage, CGRect, CALayer)]? //(UIImage: flag, CGRect: flag rect, CALayer: flag number)
            if let range = dataRange {
                for index in range {
                    let flagTime = self.flagsTimeArray[index]
                    let x = (flagTime - startTime) * self.widthPerSecond
                    var rect = self.flagRect
                    rect.origin.x = x
                    
                    if self.displayingImages[index] != nil {
                        needMoveViews.updateValue(rect, forKey: index)
                    } else {
                        let numImageName = String(format: "flag_num_%02d", index + 1)
                        let numImageLayer = CALayer()
                        if let image = UIImage(named: numImageName)?.cgImage {
                            numImageLayer.contents = image
                            numImageLayer.frame = CGRect(x: 0, y: 0, width: 15.33, height: 13.33)
                        } else {
                            continue
                        }
                        
                        let image = UIImage(named: "main_flag.9")!.stretchableImage(withLeftCapWidth: 0, topCapHeight: 25)
                        self.displayingImages.updateValue(image, forKey: index)
                        if needAddViews == nil {
                            needAddViews = [Int: (UIImage, CGRect, CALayer)]()
                        }
                        needAddViews!.updateValue((image, rect, numImageLayer), forKey: index)
                    }
                }
            }
            self.measure.end()
            
            DispatchQueue.main.sync {
                if let removeViews = needRemovedViewsTag {
                    for tag in removeViews {
                        self.viewWithTag(tag + 1)?.removeFromSuperview()
                    }
                }
                for (index, rect) in needMoveViews {
                    self.viewWithTag(index + 1)?.frame = rect
                }
                if let addViews = needAddViews {
                    for (index, (image, rect, numLayer)) in addViews {
                        let imageView = UIImageView(image: image)
                        imageView.layer.addSublayer(numLayer)
                        imageView.tag = index + 1
                        imageView.frame = rect
                        self.addSubview(imageView)
                    }
                }
            }
        }
    }
}
