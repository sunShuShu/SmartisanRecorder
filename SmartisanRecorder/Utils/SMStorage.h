//
//  SMStorage.h
//  SmartisanRecorder
//
//  Created by sunda on 2017/11/14.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMStorage : NSObject

- (instancetype)initWithDatabasePath:(NSURL *)fileUrl;

- (BOOL)createTable:(NSString *)name class:(Class)cls;
- (BOOL)dropTable:(NSString *)name;

- (BOOL)insertObject:(id)model intoTable:(NSString *)table;
- (BOOL)deleteRow:(id)content column:(NSString *)column fromTable:(NSString *)table;
- (BOOL)getAllObject:(id)model fromTable:(NSString *)table;

@end
