//
//  DateUtil.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DateUtil.h"


@implementation DateUtil
static NSDateFormatter* DATE_FORMAT = nil;
static NSDateFormatter* SHORT_DATE_FORMAT = nil;
static NSDateFormatter *timeOnlyFormat;
static NSDateFormatter *dateOnlyFormat;

+(void)initialize{
    if (!DATE_FORMAT) {
        DATE_FORMAT = [[NSDateFormatter alloc] init];
        [DATE_FORMAT setDateFormat:LONG_TIME_FORMAT_STR];
    }
    if (!SHORT_DATE_FORMAT) {
        SHORT_DATE_FORMAT = [[NSDateFormatter alloc] init];
        [SHORT_DATE_FORMAT setDateFormat:SHORT_TIME_FORMAT_STR];
    }
    if(!timeOnlyFormat){
        timeOnlyFormat = [[NSDateFormatter alloc] init];
        [timeOnlyFormat setDateFormat:@"HH:mm"];
    }
    if(!dateOnlyFormat){
        dateOnlyFormat = [[NSDateFormatter alloc] init];
        [dateOnlyFormat setDateFormat:@"MM-dd"];
    }
    
}

+(NSDate*) dateFromString:(NSString *)dateString{
    NSDateFormatter *df = nil;
    if (dateString.length == 10) {
        df = SHORT_DATE_FORMAT;
    } else if (dateString.length >= 18) { //with microseconds, remove it
        dateString = [dateString substringToIndex:18];
        df = DATE_FORMAT;
    } 
   
    return [df dateFromString:dateString];
}

+(NSDate*) dateFromShortString:(NSString *)dateString{
    return [SHORT_DATE_FORMAT dateFromString:dateString];
}

+(NSString*) humanReadableIntervalsFromDate:(NSDate*)date{
    NSTimeInterval interval = [date timeIntervalSinceNow] > 0 ? 0 : -[date timeIntervalSinceNow];
    return [DateUtil humanReadableIntervals: interval];
}
+(NSString*) humanReadableIntervals:(NSTimeInterval)interval{
    int seconds = interval;
    if( seconds < 60){
//        return [NSString stringWithFormat:@"%d%@", seconds, NSLocalizedString(@"SecondsAgo", nil)];
        return @"刚刚";
    }
    int minutes = seconds / 60;
    if(minutes < 60) {
        return [NSString stringWithFormat:@"%d%@", minutes, NSLocalizedString(@"MinutesAgo", nil)];
    }
    int hours = minutes / 60;
    if(hours < 24) {
        return [NSString stringWithFormat:@"%d%@", hours, NSLocalizedString(@"HoursAgo", nil)];
    }
    int days = hours / 24;
    if(days < 365) {
        return [NSString stringWithFormat:@"%d%@", days, NSLocalizedString(@"DaysAgo", nil)];
    }
    //how about weeks and months?
    int years = days / 365;
    if(years < 5) {
        return [NSString stringWithFormat:@"%d%@", years, NSLocalizedString(@"YearsAgo", nil)];
    }
    return NSLocalizedString(@"LongTimeAgo", nil);
}

+(NSString*) userFriendlyStringFromDate:(NSDate*)date{
    if ([DateUtil isToday:date] ) {
        return [timeOnlyFormat stringFromDate:date];
    } else {
        return [dateOnlyFormat stringFromDate:date];
    }
}

+(BOOL)isToday:(NSDate*)date{
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate* today = [cal dateFromComponents:components];
    components = [cal components:(NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSDate* otherDay = [cal dateFromComponents:components];
    return [today isEqualToDate:otherDay];
}
+(NSString*) shortStringFromDate:(NSDate*)date{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm - MM.dd"];    
    return [df stringFromDate:date];
}

+(NSString*) longStringFromDate:(NSDate*)date{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd"];    
    return [df stringFromDate:date];
}

+(NSString*) fullStringFromDate:(NSDate*)date{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss"];
    return [df stringFromDate:date];
}

+(NSInteger)ageFromBirthday:(NSDate*)birthday{
     return -[birthday timeIntervalSinceNow] / (60 * 60 * 24 * 365); 
}

+(NSString*)constellationFromBirthday:(NSDate*)birthday{
    if (!birthday) {
        return @"X星座";
    }
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:birthday];
    NSInteger d = [components day];
    NSInteger m = [components month];

    NSString *astroString = @"魔羯水瓶双鱼白羊金牛双子巨蟹狮子处女天秤天蝎射手魔羯";
    NSString *astroFormat = @"102123444543";
    NSString *result;

    if (m<1 || m>12 || d<1 || d>31) {
        return @"错误日期格式!";
    }

    if(m==2 && d>29) {
        return @"错误日期格式!!";
    } else if(m==4 || m==6 || m==9 || m==11) {
        if (d>30) {
            return @"错误日期格式!!!";
        } 
    }

    result=[NSString stringWithFormat:@"%@",[astroString substringWithRange:NSMakeRange(m*2-(d < [[astroFormat substringWithRange:NSMakeRange((m-1), 1)] intValue] - (-19))*2,2)]];
    return [NSString stringWithFormat:@"%@座", result];
}

+(NSString*)weekday:(NSDate*)date{
    NSCalendar* cal = [NSCalendar currentCalendar];
    NSDateComponents* comp = [cal components:NSWeekdayCalendarUnit fromDate:date];
    switch ([comp weekday]) {
        case 1:
            return @"星期天";
        case 2:
            return @"星期一";
        case 3:
            return @"星期二";
        case 4:
            return @"星期三";
        case 5:
            return @"星期四";
        case 6:
            return @"星期五";
        case 7:
            return @"星期六";
    }
    return nil;
}
@end
