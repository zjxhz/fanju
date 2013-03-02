//
//  LoginViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/8/12.
//
//

#import "LoginViewController.h"
#import "ActivationViewController.h"
#import "NewSidebarViewController.h"
#import "SVProgressHUD.h"

@interface LoginViewController (){
    IBOutlet UIImageView* _weiboLoginImageView;
    IBOutlet UIImageView* _qqLoginImageView;
}

@end

@implementation LoginViewController

- (id)init
{
    return [self initWithNibName:@"LoginViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"登录";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelLogin:)];
        self.navigationItem.leftBarButtonItem = nil;
        [self.navigationItem hidesBackButton];  
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    _weiboLoginImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWithWeibo:)];
    [_weiboLoginImageView addGestureRecognizer:tapGestureRecognizer];
    [Authentication sharedInstance].delegate = self;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)cancelLogin:(id)sender{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

-(IBAction)loginWithEmail:(id)sender{
    ActivationViewController* avc = [[ActivationViewController alloc] init];
    [self.navigationController pushViewController:avc animated:YES];
}

-(IBAction)loginWithWeibo:(id)sender{
    [[Authentication sharedInstance] loginAsSinaWeiboUser:self];
}

-(IBAction)loginWithQQ:(id)sender{

}

#pragma mark AuthenticationDelegate
-(void)userDidLogIn:(UserProfile *)user{
    [SVProgressHUD dismissWithSuccess:@"登录成功" afterDelay:1];
    [self dismissModalViewControllerAnimated:YES];
    if(![[Authentication sharedInstance].currentUser hasCompletedRegistration]){
//        [[NewSidebarViewController sideBar] showRegistrationWizard]; disable for now
    }
}

-(void)userFailedToLogInWithError:(NSString *)error{
    [SVProgressHUD dismissWithError:error afterDelay:1];
}

@end
