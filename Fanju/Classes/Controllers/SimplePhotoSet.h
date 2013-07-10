//
//  SimplePhotoSet.h
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SimplePhotoSet : NSObject 
@property(nonatomic, strong) NSArray* thumbnailUrls;
@property(nonatomic, strong) NSArray* largeUrls;
-(NSInteger) numberOfPhotos;
- (NSString*)largePhotoAtIndex:(NSInteger)index;
- (NSString*)thumbnailUrlAtIndex:(NSInteger)index;

@end
