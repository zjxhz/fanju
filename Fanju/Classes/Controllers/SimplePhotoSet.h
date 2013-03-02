//
//  SimplePhotoSet.h
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol PhotoSet 
@property (nonatomic, readonly) NSInteger numberOfPhotos;
- (UIImage*)photoAtIndex:(NSInteger)index;
@end


@interface SimplePhotoSet : NSObject<PhotoSet>
@property (nonatomic, retain) NSArray *photos;
- (SimplePhotoSet*) initWithPhotos:(NSArray*) photos;
@end
