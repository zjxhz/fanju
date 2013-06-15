//
//  SearchUserViewController.m
//  Fanju
//
//  Created by Xu Huanze on 6/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SearchUserViewController.h"
#import "NetworkHandler.h"
#import "UserListViewController.h"
#import "InfoUtil.h"
#import "SVProgressHUD.h"
@interface SearchUserViewController (){
    BOOL _enableSearching;
}

@end

@implementation SearchUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _textField.delegate = self;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    self.title = @"查找朋友";
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_textField becomeFirstResponder];
    _enableSearching = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    _enableSearching = NO;
}

#pragma mark UITextFieldDelegate
//- (void)textFieldDidEndEditing:(UITextField *)textField{
//    if (!_enableSearching) {
//        return;
//    }
//    
//}

-(void)searchUser{
    [SVProgressHUD showSuccessWithStatus:@"正在查找"];
    NSString* name =  _textField.text;//[_textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    RKObjectManager* manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"user/" parameters:@{@"name__icontains":name} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [SVProgressHUD dismiss];
        if (mappingResult.count > 0) {
            UserListViewController* vc = [[UserListViewController alloc] initWithStyle:UITableViewStylePlain];
            [vc viewDidLoad];
            vc.baseURL = [NSString stringWithFormat:@"user/?name__icontains=%@", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [InfoUtil showAlert:@"无法找到该用户，请检查输入"];
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"发生未知错误，请稍后重试"];
        DDLogError(@"unkonwn error while requesting users with name %@: %@", name, error);
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [self searchUser];
    return YES;
}

-(NSString *) urlEncoded
{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)self,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
    return (NSString*)CFBridgingRelease(urlString);
}
@end
