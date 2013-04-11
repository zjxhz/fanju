//
//  OrderInfo.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MealInfo.h"

@interface OrderInfo : NSObject
@property(nonatomic) int oID;
@property(nonatomic, copy) MealInfo* meal;
@property(nonatomic) int numerOfPersons;
@property(nonatomic, copy) NSString *code;
@property(nonatomic, copy) UserProfile* customer;
@property (nonatomic, copy) NSDate *createdTime;
@property(nonatomic) NSInteger status;

+(OrderInfo*) orderInfoWithData:(NSDictionary*) data;

@end
