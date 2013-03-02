//
//  LabelWithInsets.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LabelWithInsets.h"

@implementation LabelWithInsets

@synthesize leftInset;
@synthesize rightInset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.leftInset = 5;
        self.rightInset = 5;

    }
    return self;
}

- (id)initWithFrame:(CGRect)frame leftInset:(int)addtionalLeftSpace rightInset:(int)additionalRightSpace
{
    self = [super initWithFrame:frame];
    if (self) {
        self.leftInset = addtionalLeftSpace;
        self.rightInset = additionalRightSpace;
    }
    return self;
}

//
//-(id)initWithFrame:(CGRect)frame insets:(UIEdgeInsets)insets{
//    self = [super initWithFrame:frame];
//    if(self){
//        self.insets = insets;
//    }
//    return self;
//}

-(void)drawRect:(CGRect)rect{
    UIEdgeInsets insets = {0,leftInset,0,0};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

-(void)sizeToFit{
    [super sizeToFit];
    CGRect newFrame = self.frame;
    newFrame.size.width = self.leftInset + self.frame.size.width + self.rightInset;
    self.frame = newFrame;
}
@end
