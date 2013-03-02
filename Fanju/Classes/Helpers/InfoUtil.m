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
    [SVProgressHUD show];
    [SVProgressHUD dismissWithError:NSLocalizedString([dict objectForKey:@"info"], nil) afterDelay:2];
}

+(void) showErrorWithString:(NSString*) error{
    [SVProgressHUD show];
    [SVProgressHUD dismissWithError:NSLocalizedString(error, nil) afterDelay:2];
}
@end
