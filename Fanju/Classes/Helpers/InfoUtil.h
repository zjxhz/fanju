//
//  InfoUtil.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+ParseHelper.h"

@interface InfoUtil : NSObject
+(void) showError:(NSDictionary*) dict;

+(void) showErrorWithString:(NSString*) error;
@end
