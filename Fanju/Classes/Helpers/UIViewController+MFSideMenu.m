//
//  UIViewController+UIViewController_MFSideMenu.m
//  Fanju
//
//  Created by Xu Huanze on 3/4/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//
#import "MFSideMenu.h"
#import "UIViewController+MFSideMenu.h"
#import "Const.h"
#import <QuartzCore/QuartzCore.h>
#import "Three20/Three20.h"
#import "MessageService.h"
#import "NotificationService.h"
extern NSInteger UnreadCount;

@implementation UIViewController (MFSideMenu)

-(void)setupSideMenuBarButtonItem{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EOUnreadCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadDidUpdate:) name:EOUnreadCount object:nil];
    
    switch (self.navigationController.sideMenu.menuState) {
        case MFSideMenuStateClosed:
            if([[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
                self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
            } else {
                self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
            }
            break;
        case MFSideMenuStateLeftMenuOpen:
            self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
            break;
        case MFSideMenuStateRightMenuOpen:
            //NO RIGHT MENU FOR NOW
            break;
    }
}

+ (UIImage *)defaultImage {
	static UIImage *defaultImage = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.f, 13.f), NO, 0.0f);
		
		[[UIColor blackColor] setFill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 20, 1)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 5, 20, 1)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 10, 20, 1)] fill];
		
		[[UIColor whiteColor] setFill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 1, 20, 2)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 6,  20, 2)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 11, 20, 2)] fill];
		
		defaultImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
        
	});
    return defaultImage;
}

- (UIBarButtonItem *)leftMenuBarButtonItem {
    UIView* customView = [[UIView alloc] initWithFrame:CGRectZero];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonImage = [UIImage imageNamed:@"more_normal"];
    UIImage *buttonPressedImage = [UIImage imageNamed:@"more_push"] ;
    if ([VersionUtil isiOS7]) {
        buttonPressedImage = buttonImage = [[self class] defaultImage];
    }
    
    button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
    
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [button addTarget:self.navigationController.sideMenu action:@selector(toggleLeftSideMenu) forControlEvents:UIControlEventTouchUpInside];
    

    [customView addSubview:button];
    CGFloat viewWidth = buttonImage.size.width;
    if (UnreadCount == 0) {
        UnreadCount = [NotificationService service].unreadNotifCount + [MessageService service].unreadMessageCount;
    }
    if (UnreadCount) {
        UIImage* xiaoxi = [UIImage imageNamed:@"xiaoxi"];
        CGFloat x = buttonImage.size.width;
        CGFloat y = (buttonImage.size.height - xiaoxi.size.height) / 2;
        UIButton* unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [unreadButton setBackgroundImage:xiaoxi forState:UIControlStateNormal];
        unreadButton.frame = CGRectMake(x, y, xiaoxi.size.width, xiaoxi.size.height);
        [unreadButton setTitle:[NSString stringWithFormat:@"%d", UnreadCount] forState:UIControlStateNormal];
        unreadButton.titleLabel.textColor = [UIColor whiteColor];
        unreadButton.titleLabel.font = [UIFont systemFontOfSize:12];
        unreadButton.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.5).CGColor;
        unreadButton.layer.shadowOffset = CGSizeMake(0, 1);
        unreadButton.userInteractionEnabled = NO;
        
        viewWidth += xiaoxi.size.width;
        [customView addSubview:unreadButton];
    }
    customView.frame = CGRectMake(0, 0, viewWidth, buttonImage.size.height);
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
    return buttonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(backButtonPressed:)];
}

-(void)unreadDidUpdate:(NSNotification*)notif{
    UnreadCount = [notif.object integerValue];
    [self setupSideMenuBarButtonItem];
    
}
@end
