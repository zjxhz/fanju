//
//  MealTableItem.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealTableItem.h"

@implementation MealTableItem

@synthesize mealInfo = _mealInfo;

+ (id)itemWithMealInfo:(MealInfo*)mealInfo {
    MealTableItem *item = [[self alloc] init];
	item.mealInfo = mealInfo;
    
	return item;
}

#pragma mark -
#pragma mark NSObject

- (id)init {  
	if (self = [super init]) {  
		_mealInfo = nil;
	}
    
	return self;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {  
        self.mealInfo = [decoder decodeObjectForKey:@"mealInfo"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {  
    [super encodeWithCoder:encoder];
    
    if (self.mealInfo) {
        [encoder encodeObject:self.mealInfo
                       forKey:@"mealInfo"];
    }
}

- (NSComparisonResult)compare:(MealTableItem *)other{
    return [self.mealInfo compare:other.mealInfo];
}

@end
