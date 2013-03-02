//
//  UserTableItem.h
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserProfile.h"
#import <Three20/Three20.h>

@interface UserTableItem : TTTableImageItem

@property (nonatomic, strong) UserProfile *profile;
@property (nonatomic) BOOL withAddButton;

+ (id)itemWithProfile:(UserProfile*)profile withAddButton:(BOOL)withAdd;

@end
