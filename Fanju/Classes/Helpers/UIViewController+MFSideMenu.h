//
//  UIViewController+UIViewController_MFSideMenu.h
//  Fanju
//
//  Created by Xu Huanze on 3/4/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (MFSideMenu)
-(void)setupSideMenuBarButtonItem;
- (UIBarButtonItem *)leftMenuBarButtonItem ;
- (UIBarButtonItem *)backBarButtonItem;

@end
