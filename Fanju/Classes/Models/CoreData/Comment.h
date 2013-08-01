//
//  Comment.h
//  Fanju
//
//  Created by Xu Huanze on 7/24/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * cID;
@property (nonatomic, retain) Comment *parent;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) NSSet *replies;
@end

@interface Comment (CoreDataGeneratedAccessors)

- (void)addRepliesObject:(Comment *)value;
- (void)removeRepliesObject:(Comment *)value;
- (void)addReplies:(NSSet *)values;
- (void)removeReplies:(NSSet *)values;

@end
