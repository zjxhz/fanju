//
//  ActivationViewController.m
//  iMobileTracker
//
//  Created by Liu Xiaozhi on 8/19/11.
//  Copyright 2011 Vobile Inc.. All rights reserved.
//

#import "ActivationViewController.h"
#import "SBJson.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "SCAppUtils.h"
#import <Three20/Three20.h>
#import "SVProgressHUD.h"
#import "Const.h"
#import "NetworkHandler.h"
#import "UserProfile.h"
#import "DictHelper.h"
#import "NewSidebarViewController.h"

@interface ActivationViewController (){
}

@property (nonatomic, strong) UITableView *table;

@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) NSArray *placeholders;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ActivationViewController

@synthesize labels = _labels, placeholders = _placeholders;
@synthesize table = _table;

#pragma mark - View lifecycle
-(id)init{
    if (self = [super init]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelLogin:)];
        self.title = @"登录";
    }
    return self;
}

-(void)cancelLogin:(id)sender{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)loadView {
    [super loadView];
    [Authentication sharedInstance].delegate = self;
    //nav bar
    [SCAppUtils customizeNavigationController:self.navigationController];

    TTButton *btn = [TTButton buttonWithStyle:@"embossedBackButton:" title:NSLocalizedString(@"Back", nil)];
    [btn addTarget:[self presentedViewController] 
            action:@selector(dismissModalViewControllerAnimated:) 
  forControlEvents:UIControlEventTouchDown];
    btn.font = [UIFont systemFontOfSize:13];
    [btn sizeToFit];
}

- (void)initItems {
        self.labels = [NSArray arrayWithObjects:@"用户名", @"密码", @"登陆", nil];
        
        self.placeholders = [NSArray arrayWithObjects:NSLocalizedString(@"UserPlaceholder", nil), NSLocalizedString(@"PassPlaceholder", nil), @"Button",@"Button2", nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initItems];
    [self.view setBackgroundColor:RGBACOLOR(0, 0, 0, 0.5)];
    
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0, 13, 320, 208)
                                              style:UITableViewStyleGrouped];
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.table setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.table];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)login {
    ELCTextfieldCell *textCell = (ELCTextfieldCell*)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([textCell.rightTextField.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"LoginFillAlert", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    [textCell.rightTextField resignFirstResponder];
    NSString *user = textCell.rightTextField.text;
    
    textCell = (ELCTextfieldCell*)[self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if ([textCell.rightTextField.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"LoginFillAlert", nil)
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    [textCell.rightTextField resignFirstResponder];
    NSString *pass = textCell.rightTextField.text;
    [[Authentication sharedInstance] loginWithUserName:user password:pass];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient networkIndicator:YES];
}

- (void)logout {
    [[Authentication sharedInstance] logout];
}

#pragma mark -
#pragma mark Table view data source

- (void)configureCell:(ELCTextfieldCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if ([[self.placeholders objectAtIndex:indexPath.row] isEqualToString:@"Button"]) {
        cell.button.hidden = NO;
        cell.leftLabel.hidden = YES;
        cell.rightTextField.hidden = YES;
        [cell.button setTitle:[self.labels objectAtIndex:indexPath.row] forState:UIControlStateNormal];
        cell.indexPath = indexPath;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else if ([[self.placeholders objectAtIndex:indexPath.row] isEqualToString:@"Button2"]){
        cell.button.hidden = NO;
        cell.leftLabel.hidden = YES;
        cell.rightTextField.hidden = YES; 
        UIImage* image = [UIImage imageNamed:@"weibo_user_login.png"] ;
        [cell.button setBackgroundImage:image forState:UIControlStateNormal];
        cell.button.frame = CGRectMake((cell.frame.size.width - image.size.width) / 2, (cell.frame.size.height - image.size.height) / 2, image.size.width, image.size.height);
//        [cell.button sizeToFit];
        cell.indexPath = indexPath;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }else {
        cell.button.hidden = YES;
        cell.leftLabel.hidden = NO;
        cell.rightTextField.hidden = NO;
        [cell.rightTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [cell.rightTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [cell.rightTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        
        cell.leftLabel.text = [self.labels objectAtIndex:indexPath.row];

            
        cell.rightTextField.placeholder = [self.placeholders objectAtIndex:indexPath.row];
        cell.indexPath = indexPath;
        cell.delegate = self;
        //Disables UITableViewCell from accidentally becoming selected.
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == 1) {
            [cell.rightTextField setSecureTextEntry:YES];
            cell.rightTextField.text = @"";
        } else {
            [cell.rightTextField setSecureTextEntry:NO];
            cell.rightTextField.text = [Authentication sharedInstance].currentUser.username;
        }
    }
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.labels count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    ELCTextfieldCell *cell = (ELCTextfieldCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ELCTextfieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	[self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark ELCTextFieldCellDelegate Methods

-(void)textFieldDidReturnWithIndexPath:(NSIndexPath*)indexPath {        
    [self login];
}

- (void)updateTextLabelAtIndexPath:(NSIndexPath*)indexPath string:(NSString*)string {
	
}

-(void)buttonClickedWithIndexPath:(NSIndexPath*)_indexPath {
    int row = _indexPath.row;    
    if (row == 2) {
        [self login];
    } else if (row == 3){
        [[Authentication sharedInstance] loginAsSinaWeiboUser:self];
    }
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

-(void)userDidLogout:(UserProfile *)user{
    [self initItems];
    [self.table reloadData];
}

@end
