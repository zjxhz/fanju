//
//  MealComment.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"

@interface MealComment : NSObject
@property(nonatomic) int mID;
@property(nonatomic, copy) UserProfile* from_person;
@property(nonatomic, copy) NSString* comment;
@property(nonatomic, copy) NSDate* time;

- (MealComment*) initWithData:(NSDictionary*)data;

@end
