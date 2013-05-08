//
//  FJLoggerFormatter.m
//  Fanju
//
//  Created by Xu Huanze on 5/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "FJLoggerFormatter.h"

@implementation FJLoggerFormatter
-(id)init{
    if((self = [super init]))
    {
        _threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [_threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [_threadUnsafeDateFormatter setDateFormat:@"MM-dd HH:mm:ss:SSS"];
    }
    return self;
}
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR : logLevel = @"ERROR"; break;
        case LOG_FLAG_WARN  : logLevel = @"WARN"; break;
        case LOG_FLAG_INFO  : logLevel = @"INFO"; break;
        default             : logLevel = @"VERBOSE"; break;
    }
    
    NSString *dateAndTime = [_threadUnsafeDateFormatter stringFromDate:(logMessage->timestamp)];
    NSString *logMsg = logMessage->logMsg;
    
    return [NSString stringWithFormat:@"%@ %@ | %@\n", logLevel, dateAndTime, logMsg];
}

@end
