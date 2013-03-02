//
//  CommentTableItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "UserProfile.h"
@interface CommentTableItem : TTTableImageItem
@property (nonatomic, copy) UserProfile *user;
@property (nonatomic, copy) NSString* comment;

+ (id)itemFromUser:(UserProfile*)user withComment:(NSString*)comment;
@end
