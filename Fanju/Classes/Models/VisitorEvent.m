//
//  VisitorEvent.m
//  Fanju
//
//  Created by Xu Huanze on 3/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "VisitorEvent.h"

@implementation VisitorEvent
-(id)init{
    if (self = [super init]) {
        self.eventDescription = @"查看了你的资料";
        self.userFieldName = @"visitor";
    }
    return self;
}
@end
