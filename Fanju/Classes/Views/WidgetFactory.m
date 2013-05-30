//
//  WidgetFactory.m
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "WidgetFactory.h"
#import <QuartzCore/QuartzCore.h>

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
    [titleLabel sizeToFit];
    return  titleLabel;
}

-(UIBarButtonItem*)normalBarButtonItemWithTitle:(NSString*)title  target:(id)target action:(SEL)action{

    UIFont* font = [UIFont systemFontOfSize:12];
    UIImage* toprt = [UIImage imageNamed:@"toprt"] ;
    UIImage* toprt_resize =[toprt resizableImageWithCapInsets:UIEdgeInsetsMake(14, 24, 15, 25)];
    CGFloat width = MAX([title sizeWithFont:font].width + 20, toprt.size.width);
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = font;
    button.titleLabel.textColor = RGBCOLOR(220, 220, 220);
    button.titleEdgeInsets = UIEdgeInsetsMake(2, 0, 0, 0);

    [button setTitle:title forState:UIControlStateNormal];

    button.frame = CGRectMake(0, 0, width, toprt.size.height);
    [button setBackgroundImage:toprt_resize forState:UIControlStateNormal];
//    [button setBackgroundImage:[UIImage imageNamed:@"toprt_push"] forState:UIControlStateSelected | UIControlStateHighlighted];
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
//    [button sizeToFit];
    return [[UIBarButtonItem alloc] initWithCustomView:button];

}

-(UIView*)tabBarInView:(UIView*)view withButton:(UIButton*)button{
    UIImage* toolbarShadow = [UIImage imageNamed:@"toolbar_shadow"];
    UIImage* bg = [UIImage imageNamed:@"toolbar_bg"];
    UIView* tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, view.frame.size.height - bg.size.height, bg.size.width, bg.size.height)];
    tabBar.backgroundColor = [UIColor colorWithPatternImage:bg];
    
    [tabBar addSubview:button];
    button.frame = CGRectMake((tabBar.frame.size.width - button.frame.size.width) / 2, (tabBar.frame.size.height - button.frame.size.height) / 2, button.frame.size.width, button.frame.size.height);
    UIImageView* shadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -toolbarShadow.size.height, toolbarShadow.size.width, toolbarShadow.size.height)];
    shadowView.image = toolbarShadow;
    [tabBar addSubview:shadowView];
    return tabBar;
}
@end
