//
//  SMStorage.m
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import "SMStorage.h"
#import <WCDB/WCDB.h>

@interface SubstituteModel : NSObject <SMStorageModel, WCTTableCoding>
@end
@implementation SubstituteModel
WCDB_IMPLEMENTATION(SubstituteModel)
WCDB_SYNTHESIZE(SubstituteModel, localID)
@synthesize localID;

@end

@implementation SMStorage {
    WCTTable *_table;
    Class<SMStorageModel, WCTTableCoding> _cls;
}

- (id)init {
    NSAssert(NO, @"Instead of initWithDatabasePath:table:class:");
    return nil;
}

- (instancetype)initWithDatabasePath:(NSString *)path table:(NSString *)table class:(Class<SMStorageModel>)cls errorBlock:(void(^)(NSError*))block {
    self = [super init];
    if (self) {
        if (block) {
            [WCTStatistics SetGlobalErrorReport:^(WCTError *error) {
                if (error.type != WCTErrorTypeSQLiteGlobal) {
                    block(error);
                } else {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                }
            }];
        }
        if ([cls conformsToProtocol:@protocol(SMStorageModel)] &&
            [cls conformsToProtocol:@protocol(WCTTableCoding)]) {
            _cls = (Class<SMStorageModel, WCTTableCoding>)cls;
        } else {
            NSAssert(NO, @"Model class must comforms SMStorageModel and WCTTableCoding.");
            return nil;
        }
        WCTDatabase *database = [[WCTDatabase alloc] initWithPath:path];
        if (NO == [database canOpen]) {
            return nil;
        }
        if (NO == [database isTableExists:table]) {
            BOOL createResult = [database createTableAndIndexesOfName:table withClass:(Class<WCTTableCoding>)cls];
            if (NO == createResult) {
                return nil;
            }
        }
        _table = [database getTableOfName:table withClass:_cls];
    }
    return self;
}

- (BOOL)insertObject:(id)obj {
    if (NO == [obj isMemberOfClass:_cls]) {
        NSAssert(NO, @"Class of the object is not same to table's.");
        return NO;
    }
    if ([_table insertObject:obj]) {
        [obj setValue:[obj valueForKey:@"lastInsertedRowID"] forKey:@"localID"];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)deleteObject:(NSInteger)localID {
    return [_table deleteObjectsWhere:SubstituteModel.localID == localID];
}

- (BOOL)updateObject:(id)obj {
    if (NO == [obj isMemberOfClass:_cls]) {
        NSAssert(NO, @"Class of the object is not same to table's.");
        return NO;
    }
    return [_table insertOrReplaceObject:obj];
}

- (NSArray *)getAllObjects {
    return [_table getAllObjects];
}

@end
