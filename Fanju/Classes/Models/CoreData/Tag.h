//
//  Tag.h
//  Fanju
//
//  Created by Xu Huanze on 5/17/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * tID;
@property (nonatomic, retain) NSSet *user;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addUserObject:(User *)value;
- (void)removeUserObject:(User *)value;
- (void)addUser:(NSSet *)values;
- (void)removeUser:(NSSet *)values;

@end
