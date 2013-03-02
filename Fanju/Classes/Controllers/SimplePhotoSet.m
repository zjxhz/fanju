//
//  SimplePhotoSet.m
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimplePhotoSet.h"

@implementation SimplePhotoSet

@synthesize photos = _photos;

@synthesize numberOfPhotos = _numberOfPhotos;

- (SimplePhotoSet*) initWithPhotos:(NSArray*) photos{
    if (self = [super init]) {
        self.photos = photos;
    }
    return self;
}

-(NSInteger) numberOfPhotos{
    return _photos.count;
}

- (UIImage*)photoAtIndex:(NSInteger)index{
    return [_photos objectAtIndex:index];
}

@end
