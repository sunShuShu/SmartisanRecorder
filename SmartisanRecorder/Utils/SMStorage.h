//
//  SMStorage.h
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SMStorageModel <NSObject>
@property(nonatomic, readonly, assign) NSInteger localID;
@end

@interface SMStorage : NSObject
/**
 Init database

 @param path database file path
 @param table table name
 @param cls class of model stored (must confirm WCTTableCoding protocol)
 @param block error block of database opration
 @return object
 */
- (id _Nullable)initWithDatabasePath:(NSString *_Nonnull)path
                               table:(NSString *_Nonnull)table
                               class:(Class<SMStorageModel> _Nonnull)cls
                          errorBlock:(void(^_Nullable)(NSError*_Nonnull))block;

- (BOOL)insertObject:(id _Nonnull)obj;
- (BOOL)deleteObject:(NSInteger)localID;
- (BOOL)modifyObject:(id _Nonnull)obj;
- (NSArray *_Nullable)getAllObjects;

@end
