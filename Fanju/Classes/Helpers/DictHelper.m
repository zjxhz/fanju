//
//  DictHelper.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DictHelper.h"

@implementation DictHelper

+(NSDictionary*)dictWithKey:(NSString*)key andValue:(NSString*)value{
    return [NSDictionary dictionaryWithObjectsAndKeys:value, @"value", key, @"key", nil];
}

@end
