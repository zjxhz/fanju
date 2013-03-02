//
//  UserImageView.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserImageView.h"

@implementation UserImageView
@synthesize user = _user, tapDelegate = _tapDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUserInteractionEnabled:YES];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)tapped:(id)sender{
    [_tapDelegate userImageTapped:_user];
}

@end
