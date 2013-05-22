//
//  RelationshipService.h
//  Fanju
//
//  Created by Xu Huanze on 5/21/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RelationshipService : NSObject
+(RelationshipService*)service;
-(void)fetchFollowingsForUser:(User*)user;
-(BOOL)isLoggedInUserFollowing:(User*)anotherUser;
-(void)follow:(User*)user;
-(Relationship*)relationWith:(User*)user;
@end
