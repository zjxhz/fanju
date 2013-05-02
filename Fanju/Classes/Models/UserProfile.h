//
//  UserProfile.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mapkit/Mapkit.h"
#import "UserTag.h"
#import "UserPhoto.h"

@interface UserProfile : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, copy) NSDate *birthday;
@property (nonatomic) int gender; //0 male 1 female
@property (nonatomic) int uID;
@property (nonatomic, copy) NSDate *locationUpdatedTime;
@property (nonatomic) CLLocationCoordinate2D coordinate;   
@property (nonatomic, copy) NSString* motto;
@property (nonatomic, copy) NSString* occupation;
@property (nonatomic, copy) NSString* college;
@property (nonatomic, strong) NSMutableSet *followings;
@property (nonatomic, strong) NSMutableArray *tags;
@property (nonatomic, copy) NSString* workFor;
@property (nonatomic, copy) NSString* email;
@property (nonatomic, copy) NSDate* dateJoined;
@property (nonatomic, copy) NSString* weiboID;
@property (nonatomic, strong) UIImage* avatar;//used to store local image that is not uploaded
@property (nonatomic, copy) NSMutableArray* photos;
@property (nonatomic, readonly) NSString* jabberID;
@property (nonatomic, copy) NSString* industry; //行业
+ (UserProfile *)profileWithData:(NSDictionary *)data;
-(NSInteger) age;
-(NSString*)constellation;
- (BOOL)isFollowing:(UserProfile*)user;
-(NSString*)tagsToString;
-(NSString*)avatarFullUrl;
//helper method that converts an UIImage object into the dict that can be used for uploading user image
-(NSDictionary*)avatarDictForUploading:(UIImage*)image;
-(UIImage*)genderImage;
-(BOOL)hasCompletedRegistration;
-(NSArray*)avatarAndPhotosFullUrls;
-(void)addPhoto:(UserPhoto*)photo;
-(NSInteger)industryValue;
+(NSInteger)industryValue:(NSString*)industry;
+(NSArray*) industries;
-(NSArray*)photosFullUrls;
@end
