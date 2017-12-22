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
@property(nonatomic, copy, nonnull)     NSString *name;
@property(nonatomic, assign)           NSInteger fileSize;
@property(nonatomic, strong, nonnull)     NSDate *createTime;
@property(nonatomic, assign)         SMVoiceType voiceType;
@property(nonatomic, assign)           NSInteger duration;
@property(nonatomic, assign)           NSInteger pointCount;

@end
