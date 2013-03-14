//
//  UIViewController+CustomNavigationBar.m
//  Fanju
//
//  Created by Xu Huanze on 3/14/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "UIViewController+CustomNavigationBar.h"
#import "Three20/Three20.h"

@implementation UIViewController (CustomNavigationBar)
-(void)customNavigationBar:(NSString*)textOnRight{
    UIButton *back = [[UIButton alloc] init];
    back.titleLabel.font = [UIFont systemFontOfSize:12];
    back.titleLabel.textColor = RGBCOLOR(220, 220, 220);
    [back setTitle:@"返回" forState:UIControlStateNormal];
    [back setBackgroundImage:[UIImage imageNamed:@"toplf"] forState:UIControlStateNormal];
    [back setBackgroundImage:[UIImage imageNamed:@"toplf_push"] forState:UIControlStateSelected | UIControlStateHighlighted];
    [back addTarget:self.navigationController
             action:@selector(popViewControllerAnimated:)
   forControlEvents:UIControlEventTouchDown];
    [back sizeToFit];
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
    self.navigationItem.hidesBackButton = YES;
    
    if (textOnRight) {
        UIButton *share = [[UIButton alloc] init];
        share.titleLabel.font = [UIFont systemFontOfSize:12];
        share.titleLabel.textColor = RGBCOLOR(220, 220, 220);
        [share setTitle:textOnRight forState:UIControlStateNormal];
        [share setBackgroundImage:[UIImage imageNamed:@"toprt"] forState:UIControlStateNormal];
        [share setBackgroundImage:[UIImage imageNamed:@"toprt_push"] forState:UIControlStateSelected | UIControlStateHighlighted];
        [share sizeToFit];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:share];
    }
}

@end
