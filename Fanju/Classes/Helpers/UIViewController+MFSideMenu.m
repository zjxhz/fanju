//
//  UIViewController+UIViewController_MFSideMenu.m
//  Fanju
//
//  Created by Xu Huanze on 3/4/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//
#import "MFSideMenu.h"
#import "UIViewController+MFSideMenu.h"

@implementation UIViewController (MFSideMenu)
-(void)setupSideMenuBarButtonItem{
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

- (UIBarButtonItem *)leftMenuBarButtonItem {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *buttonImage = [UIImage imageNamed:@"more_normal"];
    UIImage *buttonPressedImage = [UIImage imageNamed:@"more_push"] ;
    button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
    
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonPressedImage forState:UIControlStateHighlighted];
    [button addTarget:self.navigationController.sideMenu action:@selector(toggleLeftSideMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    return buttonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(backButtonPressed:)];
}


@end
