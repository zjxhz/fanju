#import "TabBarController.h"
#import <Three20UI/UITabBarControllerAdditions.h>
#import "AppDelegate.h"
#import "Const.h"
#import "MealListViewController.h"
#import "Authentication.h"
#import "UIViewController+JTRevealSidebarV2.h"
#import "UINavigationItem+JTRevealSidebarV2.h"
#import "JTRevealSidebarV2Delegate.h"
#import "NewSidebarViewController.h"
#import "UserMessagesViewController.h"
#import "UserMoreDetailViewController.h"

@implementation TabBarController
@synthesize leftSidebarViewController;
- (void)viewDidLoad {
    [self setTabURLs:[NSArray arrayWithObjects:@"eo://meal", @"eo://me",@"eo://social",nil]];
    self.delegate = self;
}

-(void)revealSidebar:(id)sender{
    [self toggleRevealState:JTRevealedStateLeft];
    [self.leftSidebarViewController viewWillAppear:NO];
}

-(void) setViewControllers:(NSArray *)viewControllers{
    [super setViewControllers:viewControllers];
    for (UIViewController *controller in viewControllers) {
        UINavigationController *nav = (UINavigationController*)controller;
        UIImage *sideBarImage = [UIImage imageNamed:@"city.png"];
        UIButton *sideBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sideBarButton.frame = CGRectMake(0, 0, 26, 23);
        [sideBarButton setImage:sideBarImage forState:UIControlStateNormal];
        [sideBarButton addTarget:self action:@selector(revealSidebar:) forControlEvents:UIControlEventTouchDown];
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sideBarButton];
        nav.topViewController.navigationItem.leftBarButtonItem = leftBarButtonItem;
        nav.navigationItem.revealSidebarDelegate = self;
    }
}

#pragma mark UITabBarControllerDelegate
-(BOOL) tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    if(![viewController isKindOfClass:[MealListViewController class]]){
        if(![[Authentication sharedInstance] isLoggedIn]) {        
            // not logged in
            AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [delegate showLogin];
            return NO;
        }
    }
    return YES;
    
}

#pragma mark JTRevealSidebarV2Delegate 
- (UIView *)viewForLeftSidebar{
    CGRect viewFrame =self.selectedViewController.applicationViewFrame;
    NewSidebarViewController *controller = self.leftSidebarViewController;
    if ( ! controller) {
        self.leftSidebarViewController = [[NewSidebarViewController alloc] initWithStyle:UITableViewStylePlain];
        controller = self.leftSidebarViewController ;
        controller.delegate = self;
    }
    controller.view.frame = CGRectMake(0, viewFrame.origin.y, 270, viewFrame.size.height);
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    return controller.view;
}

- (void)didChangeRevealedStateForViewController:(UIViewController *)viewController{
    UINavigationController *nav = (UINavigationController*) self.selectedViewController;
    if (viewController.revealedState == JTRevealedStateNo) {
        nav.topViewController.view.userInteractionEnabled = YES;
        self.tabBar.userInteractionEnabled = YES;
        if ( _showLoginAfterLeftBarHides) {
            AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [delegate showLogin];
        }
    } else {
        nav.topViewController.view.userInteractionEnabled = NO;
        self.tabBar.userInteractionEnabled = NO;
        
    }
}

#pragma mark SidebarViewControllerDelegate 
-(void)sidebarController:(NewSidebarViewController*)controller didSelectRow:(NSInteger)row{
    [self toggleRevealState:JTRevealedStateNo];
    _showLoginAfterLeftBarHides = NO;
    switch (row) {
        case 0:
            if (![[Authentication sharedInstance] isLoggedIn]) {
                _showLoginAfterLeftBarHides = YES;
            } else {
                UserMessagesViewController* messagesController = [[UserMessagesViewController alloc] initWithNibName:nil bundle:nil];
                messagesController.profile = [[Authentication sharedInstance] currentUser];
                [self presentModalViewControllerWithNavigationBar:messagesController];
            }
            break;
        case 1:
             _showLoginAfterLeftBarHides = YES;
            break;
        case 2:
            if (![[Authentication sharedInstance] isLoggedIn]) {
                _showLoginAfterLeftBarHides = YES;
            } else {
                UserMoreDetailViewController* more = [[UserMoreDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
                more.profile = [[Authentication sharedInstance] currentUser];
                [self presentModalViewControllerWithNavigationBar:more];
            } 
            
            break;
        default:
            break;
    }
}

-(void)presentModalViewControllerWithNavigationBar:(UIViewController*) viewController{
    UINavigationController *vc = [[UINavigationController alloc] initWithRootViewController:viewController];
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonClicked:)];
    UINavigationController *nav = (UINavigationController*) self.selectedViewController;
    [nav presentModalViewController:vc animated:YES];
}


-(void) doneButtonClicked:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
