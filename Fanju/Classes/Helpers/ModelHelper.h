//
//  Model.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelHelper : NSObject

+(NSString*) stringValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict;

+(NSString*) stringValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict withDefaultValue:(NSString*)defaultValue;

+(NSDate*) dateValueForKey:(NSString*)key inDictionary:(NSDictionary*)dict;
@end
