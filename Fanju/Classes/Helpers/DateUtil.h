//
//  DateUtil.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtil : NSObject
+(NSDate*) dateFromString:(NSString*)dateString;
+(NSDate*) dateFromShortString:(NSString *)dateString;
+(NSString*) humanReadableIntervals:(NSTimeInterval) interval;
+(NSString*) shortStringFromDate:(NSDate*)date;
+(NSString*) longStringFromDate:(NSDate*)date;
+(NSInteger)ageFromBirthday:(NSDate*)birthday;
+(NSString*)constellationFromBirthday:(NSDate*)birthday;
+(NSString*) fullStringFromDate:(NSDate*)date;
+(NSString*) userFriendlyStringFromDate:(NSDate*)date;
@end
