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

- (id _Nullable)initWithDatabasePath:(NSString *_Nonnull)path
                               table:(NSString *_Nonnull)table
                               class:(Class<SMStorageModel> _Nonnull)cls
                          errorBlock:(void(^_Nullable)(NSError*_Nonnull))block;

- (BOOL)insertObject:(id _Nonnull)obj;
- (BOOL)deleteObject:(NSInteger)localID;
- (BOOL)modifyObject:(id _Nonnull)obj;
- (NSArray *_Nullable)getAllObjects;

@end
