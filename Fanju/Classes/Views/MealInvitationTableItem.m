//
//  MealInvitationTableItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealInvitationTableItem.h"

@implementation MealInvitationTableItem
@synthesize mealInvitation = _mealInvitation;

+(id) itemWithMealInvitation:(MealInvitation *)mealInvitation{
    MealInvitationTableItem *item = [[self alloc] init];
    item.mealInvitation = mealInvitation;
    
    return item;
}

-(id) init {
    if(self = [super init]) {
        _mealInvitation = nil;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {  
        self.mealInvitation = [decoder decodeObjectForKey:@"mealInvitation"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {  
    [super encodeWithCoder:encoder];
    
    if (self.mealInvitation) {
        [encoder encodeObject:self.mealInvitation
                       forKey:@"mealInvitation"];
    }
}

@end
