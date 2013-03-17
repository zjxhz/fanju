//
//  SimpleUserEvent.m
//  Fanju
//
//  Created by Xu Huanze on 3/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SimpleUserEvent.h"

@implementation SimpleUserEvent
-(id)init{
    if (self = [super init]) {
        self.userFieldName = @"user";
    }
    return self;
}
@end
