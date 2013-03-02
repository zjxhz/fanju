#import <Three20/Three20.h>
#import "JTRevealSidebarV2Delegate.h"
#import "NewSidebarViewController.h"

@interface TabBarController : UITabBarController<UITabBarControllerDelegate,JTRevealSidebarV2Delegate, SidebarViewControllerDelegate> {
    BOOL _showLoginAfterLeftBarHides;
}
@property (nonatomic, strong) NewSidebarViewController *leftSidebarViewController;
@end
