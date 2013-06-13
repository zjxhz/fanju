//
//  UserRegistrationViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserRegistrationViewController.h"
#import "TextFormCell.h"
#import "NetworkHandler.h"
#import "DictHelper.h"
#import "Const.h"
#import "SVProgressHUD.h"
#import "Authentication.h"
#import "NameAndGenderViewController.h"

@implementation UserRegistrationViewController
@synthesize user = _user;
@synthesize nameAndGender = _nameAndGender;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    self.title = @"注册账号";
    _user = [[UserProfile alloc] init];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([[Authentication sharedInstance] isLoggedIn] && ![[Authentication sharedInstance].currentUser hasCompletedRegistration]) {
        _user = [Authentication sharedInstance].currentUser;
  
        [self fillCellsWithUserName:_user.username andPassword:_user.password];        
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未完成注册" message:@"您之前的注册尚未完成，继续之前的注册流程，还是新注册一个用户？" delegate:self cancelButtonTitle:nil otherButtonTitles:@"继续", @"注册新用户", nil];
        [a show];
    }
}

-(void)fillCellsWithUserName:(NSString*)username andPassword:(NSString*)password{
    TextFormCell* usernameCell = (TextFormCell* )[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    usernameCell.textField.text = username;
    TextFormCell* passwordCell = (TextFormCell* )[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    passwordCell.textField.text = password;
    TextFormCell* confirmPasswordCell = (TextFormCell* )[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    confirmPasswordCell.textField.text = password;    
}
-(void)next:(id)sender{
    if ([self validateEmail] && [self validatePassword]) {
        [self checkEmailOnline];
//        [self registerUser];
    }
}

-(BOOL)validateEmail{
    NSString* reg = @".+@.+\..+";
    NSString* email = [self valueForCellAtRow:0];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reg];
    if ([predicate evaluateWithObject:email]) {
        return YES;
    } else {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"未知的邮件格式" message:@"您的邮件地址似乎不被接受，如您确信邮件地址并无问题，请联系客服" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return NO;
    }
}

-(BOOL)checkEmailOnline{
    [SVProgressHUD showWithStatus:@"正在验证邮件地址…"];
    NSString* email  = [self valueForCellAtRow:0];
    NSArray *params = [NSArray arrayWithObjects:[DictHelper dictWithKey:@"email" andValue:email], nil];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/checkemail/", HTTPS, EOHOST]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSDictionary* result = obj;
                                            if ([[result objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                _user = [[UserProfile alloc] init];
                                                NSString* username  = [self valueForCellAtRow:0];
                                                NSString* password = [self valueForCellAtRow:1];
                                                _user.username = username;
                                                _user.password = password;
                                                _user.email = username;
                                                [SVProgressHUD dismiss];
                                                [self.navigationController pushViewController:self.nameAndGender animated:YES];
                                            }
                                            else {
                                                [SVProgressHUD showErrorWithStatus:[result objectForKey:@"info"]];
                                            }
                                        } failure:^{
#warning how to guide user to login as an app user in this case?
                                            [SVProgressHUD showErrorWithStatus:@"邮箱已被注册，如果您曾以该邮箱注册，请使用邮箱账号登录。或者使用其他邮箱。"];
                                        }];
    return YES;
}

-(BOOL) validatePassword{
    NSString* pass1 = [self valueForCellAtRow:1];
    if (pass1.length < 6) {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"密码长度不足6位" message:@"请检查密码长度是否符合要求" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return NO;
    } else {
        NSString* pass2 = [self valueForCellAtRow:2];
        if (![pass1 isEqualToString:pass2]) {
            UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"密码不匹配" message:@"两次输入的密码不匹配，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [a show];
            return NO;
        } 
    }
    return YES;
}

-(NSString*) valueForCellAtRow:(NSInteger)row{
    TextFormCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return cell.textField.text;
}

//-(BOOL) registerUser{
//    [[Authentication sharedInstance] logout];
//    [SVProgressHUD showWithStatus:@"正在注册…"];
//    NSString* username  = [self valueForCellAtRow:0];
//    NSString* password = [self valueForCellAtRow:1];
//    NSArray *params = [NSArray arrayWithObjects:[DictHelper dictWithKey:@"username" andValue:username], 
//                       [DictHelper dictWithKey:@"password" andValue:password], nil];
//    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/register/", HTTPS, EOHOST]
//                                         method:POST
//                                     parameters:params
//                                    cachePolicy:TTURLRequestCachePolicyNone
//                                        success:^(id obj) {
//                                            NSDictionary* result = obj;
//                                            if ([[result objectForKey:@"status"] isEqualToString:@"OK"]) {
//                                                [Authentication sharedInstance].delegate = self;
//                                                [[Authentication sharedInstance] loginWithUserName:username password:password];
//                                            } 
//                                            else {
//                                                [SVProgressHUD showErrorWithStatus:[result objectForKey:@"info"]];
//                                            }
//                                        } failure:^{
//                                            [SVProgressHUD showErrorWithStatus:@"注册失败"];
//                                        }];
//    return YES;
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"邮箱是登录饭聚的账号，也是取回密码的唯一凭证，请确保邮箱填写正确";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TextFormCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;        
    }    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"邮箱地址";
            cell.textField.placeholder = @"example@mail.com";
            cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case 1:
            cell.textLabel.text = @"密码";
            cell.textField.placeholder = @"不少于6位";
            cell.textField.secureTextEntry = YES;
            break;
        case 2:
            cell.textLabel.text = @"重复密码";
            cell.textField.placeholder = @"再次输入密码";
            cell.textField.secureTextEntry = YES;
            break;
        default:
            break;
    }   
    return cell;
}

-(NameAndGenderViewController*)nameAndGender{
    if (!_nameAndGender) {
        _nameAndGender = [[NameAndGenderViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _nameAndGender.user = _user;
    }
    return _nameAndGender;
}

//#pragma mark AuthenticationDelegate
//-(void)userDidLogIn:(UserProfile*) user{
//    _user = [[Authentication sharedInstance] currentUser];
//    _user.email = _user.username;
//    [self.navigationController pushViewController:self.nameAndGender animated:YES];
//    [SVProgressHUD dismiss];
//    [Authentication sharedInstance].delegate = nil;
//}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [self.navigationController pushViewController:self.nameAndGender animated:YES];
    }
    else if (buttonIndex == 1) {
        [self fillCellsWithUserName:nil andPassword:nil];
    }
}
@end
