//
//  ErrorInfoViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ErrorInfoViewController.h"
#import "Const.h"

@interface ErrorInfoViewController (){
    NSString* _html;
    UIWebView *_webView;
}

@end

@implementation ErrorInfoViewController
-(id) initWithHtml:(NSString*)html{
    self = [super init];
    if (self) {
        _html = html;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    [_webView loadHTMLString:_html baseURL: EOHOST];
    [self.view addSubview:_webView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
