//
//  User.h
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Tag;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * college;
@property (nonatomic, retain) NSDate * dateJoined;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * gender;
@property (nonatomic, retain) NSString * industry;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSDate * locationUpdatedAt;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * motto;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * occupation;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * uID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * weiboID;
@property (nonatomic, retain) NSString * workFor;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *tags;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
