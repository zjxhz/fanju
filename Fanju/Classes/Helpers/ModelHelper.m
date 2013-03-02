//
//  Model.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelHelper.h"
#import "DateUtil.h"
@implementation ModelHelper

            
+(NSString*) stringValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict{
    return [ModelHelper stringValueForKey:key inDictionary:dict withDefaultValue:nil];
}

+(NSString*) stringValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict withDefaultValue:(NSString*)defaultValue{
     return [[dict objectForKey:key] isKindOfClass:[NSNull class]] ?  defaultValue : [dict objectForKey:key];
}

+(NSDate*) dateValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict{
    return [[dict objectForKey:key] isKindOfClass:[NSNull class]] ?  nil : [DateUtil dateFromString:[dict objectForKey:key]];
}

@end
