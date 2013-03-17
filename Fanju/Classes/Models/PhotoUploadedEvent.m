//
//  PhotoUploadedEvent.m
//  Fanju
//
//  Created by Xu Huanze on 3/17/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "PhotoUploadedEvent.h"

@implementation PhotoUploadedEvent
-(id)init{
    if (self = [super init]) {
        self.eventDescription = @"上传了新的照片";
    }
    return self;
}
@end
