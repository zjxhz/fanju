//
//  FJLoggerFormatter.h
//  Fanju
//
//  Created by Xu Huanze on 5/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
@interface FJLoggerFormatter : NSObject<DDLogFormatter>
@property(nonatomic, strong) NSDateFormatter* threadUnsafeDateFormatter;
@end
