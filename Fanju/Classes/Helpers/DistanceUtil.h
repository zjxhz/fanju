//
//  DistanceUtil.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import "User.h"

@interface DistanceUtil : NSObject
+(NSString*) distanceToMe:(UserProfile*)user;
+(NSString*)distanceFrom:(User*)user;
@end
