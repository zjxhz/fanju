//
//  PhotoViewController.h
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SimplePhotoSet.h"
#import <Three20/Three20.h>


@interface PhotoViewController : TTViewController<UIScrollViewDelegate, TTURLRequestDelegate>{
    NSInteger _initialIndex;
}
@property(nonatomic,retain) SimplePhotoSet* photoSource;
-(id) initWithPhotos:(NSArray*)photos atIndex:(NSInteger)index withBigPhotoUrls:(NSArray*)bigPhotoUrls;
@end
