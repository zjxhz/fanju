//
//  InfoUtil.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoUtil.h"
#import "SVProgressHUD.h"
@implementation InfoUtil

+(void) showError:(NSDictionary*) dict{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString([dict objectForKey:@"info"], nil)];
}

+(void) showAlert:(NSString*)alert{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:alert delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}
@end
