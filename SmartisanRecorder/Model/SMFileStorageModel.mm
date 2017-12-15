//
//  SMFileStorageModel.m
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import "SMFileStorageModel.h"
#import <WCDB/WCDB.h>

@interface SMFileStorageModel() <WCTTableCoding>
@end

@implementation SMFileStorageModel

WCDB_IMPLEMENTATION(SMFileStorageModel)
WCDB_SYNTHESIZE(SMFileStorageModel, localID)
WCDB_SYNTHESIZE(SMFileStorageModel, name)
WCDB_SYNTHESIZE(SMFileStorageModel, md5)
WCDB_SYNTHESIZE(SMFileStorageModel, voiceType)
WCDB_SYNTHESIZE(SMFileStorageModel, pointCount)
WCDB_SYNTHESIZE(SMFileStorageModel, pointFileName)
WCDB_SYNTHESIZE(SMFileStorageModel, waveformFileName)

WCDB_PRIMARY_ASC_AUTO_INCREMENT(SMFileStorageModel, localID)
WCDB_UNIQUE(SMFileStorageModel, name)
WCDB_NOT_NULL(SMFileStorageModel, name)
WCDB_NOT_NULL(SMFileStorageModel, md5)
WCDB_NOT_NULL(SMFileStorageModel, voiceType)
WCDB_NOT_NULL(SMFileStorageModel, pointCount)
WCDB_NOT_NULL(SMFileStorageModel, pointFileName)
WCDB_NOT_NULL(SMFileStorageModel, waveformFileName)

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isAutoIncrement = YES;
    }
    return self;
}

- (void)setLocalID:(NSInteger)localID {
    _localID = localID;
}

@end
