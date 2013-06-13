//
//  EmailViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EmailViewController.h"
#import "Authentication.h"
#import "TextFormCell.h"
#import "SVProgressHUD.h"
#import "DictHelper.h"
@interface EmailViewController ()

@end

@implementation EmailViewController
@synthesize user = _user;
@synthesize nameAndGender = _nameAndGender;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    self.title = @"邮件地址";
    _user = [Authentication sharedInstance].currentUser;
}

-(void)next:(id)sender{
    if ([self validateEmail] ) {
        [self registerUser];
    } 
}

-(BOOL)validateEmail{
    NSString* reg = @".+@.+\..+";
    NSString* email = [self valueForCellAtRow:0];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reg];
    if ([predicate evaluateWithObject:email]) {
        return YES;
    } else {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"未知的邮件格式" message:@"您的邮件地址似乎不被饭聚接受，如您确信邮件地址并无问题，请联系客服" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return NO;
    }
}


-(NSString*) valueForCellAtRow:(NSInteger)row{
    TextFormCell* cell = (TextFormCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return cell.textField.text;
}

-(BOOL) registerUser{
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
                                                _user.email = email;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"为确保您及时收到饭聚的通知，请确保邮箱填写正确";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TextFormCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;      
        cell.textLabel.text = @"邮箱地址";
        cell.textField.placeholder = @"example@mail.com";
        cell.textField.text = _user.email;
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
    }    
    return cell;
}

-(NameAndGenderViewController*)nameAndGender{
    if (!_nameAndGender) {
        _nameAndGender = [[NameAndGenderViewController alloc] initWithStyle:UITableViewStyleGrouped];
        _nameAndGender.user = _user;
        _nameAndGender.navigationItem.hidesBackButton = YES; // no way back
    }
    return _nameAndGender;
}


@end
