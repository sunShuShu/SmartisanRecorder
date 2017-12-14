//
//  SMStorage.m
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import "SMStorage.h"
#import <WCDB/WCDB.h>

@implementation SMStorage {
    WCTDatabase *_database;
}

- (id)init {
    NSAssert(NO, @"Instead of initWithDatabasePath:table:class:");
    return nil;
}

- (instancetype)initWithDatabasePath:(NSURL *)fileUrl errorBlock:(void(^)(NSError*))block {
    self = [super init];
    if (self) {
        if (block) {
            [WCTStatistics SetGlobalErrorReport:block];
        }
        _database = [[WCTDatabase alloc] initWithPath:fileUrl.absoluteString];
        if ([_database canOpen] == NO) {
            return nil;
        }
    }
    return self;
}

- (BOOL)createTable:(NSString *)name class:(Class)cls {
    return [_database createTableAndIndexesOfName:name withClass:cls];
}

- (BOOL)dropTable:(NSString *)name {
    return [_database dropTableOfName:name];
}

- (BOOL)insertObject:(id)model intoTable:(NSString *)table {
    return [_database insertObject:model into:table];
}

@end
