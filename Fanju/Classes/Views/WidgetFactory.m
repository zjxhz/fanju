//
//  WidgetFactory.m
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "WidgetFactory.h"

@implementation WidgetFactory
+(WidgetFactory*)sharedFactory {
    static WidgetFactory *factory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[WidgetFactory alloc] init];
    });
    return factory;
}

-(UIBarButtonItem*)backButtonWithTarget:(id)target action:(SEL)action{
    UIImage* backImg = [UIImage imageNamed:@"toplf"];
    UIImage* backImgPush = [UIImage imageNamed:@"toplf_push"];
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.titleLabel.font = [UIFont systemFontOfSize:12];
    back.titleLabel.textColor = RGBCOLOR(220, 220, 220);
    back.titleEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
    back.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [back setTitle:@"返回" forState:UIControlStateNormal];
    [back setBackgroundImage:backImg forState:UIControlStateNormal];
    [back setBackgroundImage:backImgPush forState:UIControlStateSelected | UIControlStateHighlighted];
    [back addTarget:target action:action forControlEvents:UIControlEventTouchDown];
    [back sizeToFit];
    return [[UIBarButtonItem alloc] initWithCustomView:back];
}

-(UIView*)titleViewWithTitle:(NSString*)title {
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:21];
    titleLabel.minimumFontSize = 14;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textColor = RGBCOLOR(220, 220, 220);
    titleLabel.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.4).CGColor;
    titleLabel.layer.shadowOffset = CGSizeMake(0, -2);
    titleLabel.frame = CGRectMake(0, 0, 200, 44);
    [titleLabel sizeToFit];
    return  titleLabel;
}

-(UIBarButtonItem*)normalBarButtonItemWithTitle:(NSString*)title  target:(id)target action:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    button.titleLabel.textColor = RGBCOLOR(220, 220, 220);
    button.titleEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);
    [button setTitle:title forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"toprt"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"toprt_push"] forState:UIControlStateSelected | UIControlStateHighlighted];
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
    [button sizeToFit];
    return [[UIBarButtonItem alloc] initWithCustomView:button];

}

@end
