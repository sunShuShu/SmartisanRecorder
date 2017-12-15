//
//  SMFileStorageModel.h
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMStorage.h"

typedef enum : NSUInteger {
    SMVoiceTypeDefault,
    SMVoiceTypeImported,
    SMVoiceTypePhontCall,
    SMVoiceTypeIdeaCapsule,
} SMVoiceType;

@interface SMFileStorageModel : NSObject <SMStorageModel>

@property(nonatomic, readonly, assign) NSInteger localID;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *md5;
@property(nonatomic, assign) SMVoiceType voiceType;
@property(nonatomic, assign) NSInteger pointCount;
@property(nonatomic, copy) NSString *pointFileName;
@property(nonatomic, copy) NSString *waveformFileName;

@end
