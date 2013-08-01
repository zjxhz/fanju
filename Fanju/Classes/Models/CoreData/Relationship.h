//
//  Relationship.h
//  Fanju
//
//  Created by Xu Huanze on 7/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Relationship : NSManagedObject

@property (nonatomic, retain) NSNumber * rID;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) User *fromPerson;
@property (nonatomic, retain) User *toPerson;

@end
