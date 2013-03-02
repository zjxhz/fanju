//
//  WeiboViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/13/13.
//
//

#import "WeiboViewController.h"

@interface WeiboViewController (){
    NSString* _weiboID;
}

@end

@implementation WeiboViewController

- (id)initWithWeiboID:(NSString*)weiboID
{
    self = [super init];
    if (self) {
        _weiboID = weiboID;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.weibo.com/u/%@", _weiboID]];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    [self.view addSubview:webView];
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
