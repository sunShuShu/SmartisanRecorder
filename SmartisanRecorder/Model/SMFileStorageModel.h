//
//  SMFileStorageModel.h
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SMVoiceTypeDefault,
    SMVoiceTypeImported,
    SMVoiceTypePhontCall,
    SMVoiceTypeIdeaCapsule,
} SMVoiceType;

@interface SMFileStorageModel : NSObject 

@property(nonatomic, assign) NSInteger localID;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *md5;
@property(nonatomic, assign) SMVoiceType voiceType;

@end
