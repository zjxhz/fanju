//
//  SimplePhotoSet.m
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimplePhotoSet.h"

@implementation SimplePhotoSet

-(NSInteger) numberOfPhotos{
    return _largeUrls.count;
}

- (NSString*)largePhotoAtIndex:(NSInteger)index{
    return _largeUrls[index];
}

- (NSString*)thumbnailUrlAtIndex:(NSInteger)index{
    return _thumbnailUrls[index];
}

@end
