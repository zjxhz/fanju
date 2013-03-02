//
//  UserPhotoSource.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserPhotoSource.h"
@implementation UserPhotoSource
@synthesize photoes = _photoes, title = _title, maxPhotoIndex = _maxPhotoIndex, numberOfPhotos = _numberOfPhotos;

-(id)initWithPhotoes:(NSArray*)photoes{
    if (self = [super init]) {
        _photoes = photoes;
        _numberOfPhotos = _photoes.count;
    }
    return self;
}
- (id<TTPhoto>)photoAtIndex:(NSInteger)index{
    return [_photoes objectAtIndex:index];
}

- (NSInteger)maxPhotoIndex {
    return _photoes.count-1;
}

- (NSInteger)numberOfPhotos {
        return _photoes.count;
}

@end

//@implementation UserPhoto
//
//@synthesize photoSource = _photoSource, size = _size, index = _index, caption = _caption;
//- (id)initWithURL:(NSString*)URL size:(CGSize)size {
//    if (self = [super init]) {
//        _photoSource = nil;
//        _URL = [URL copy];
//        _size = size;
//        _index = NSIntegerMax;
//    }
//    return self;
//}
//
//- (NSString*)URLForVersion:(TTPhotoVersion)version {
//    return _URL;
//}
//
//
//@end
