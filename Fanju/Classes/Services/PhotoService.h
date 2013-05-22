//
//  PhotoService.h
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"
typedef void(^fetch_photo_success)(Photo*);

@interface PhotoService : NSObject
+(PhotoService*)service;
-(id)init;

-(Photo*)getOrFetchPhoto:(NSString*)photoID success:(fetch_photo_success)success failure:(void (^)(void))failure;

-(void)fetchPhotoWithID:(NSString*)mID success:(void (^)(Photo* meal))success failure:(void (^)(void))failure;
-(Photo*)photoWithID:(NSString*)pID;

@end
