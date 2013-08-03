//
//  ShareTableViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ShareTableViewController.h"
#import "WidgetFactory.h"

@interface ShareTableViewController ()

@end

@implementation ShareTableViewController
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

-(void)loadView{
    [super loadView];
    //        self.contentSizeForViewInPopover = CGSizeMake(100, 3 * 44 - 1);
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    //        self.tableView.rowHeight = 44;
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"分享到"];
    self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"取消" target:self action:@selector(dismissModalViewControllerAnimated:)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3; //TODO how many social networks do we support?
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
//    cell.textLabel.textColor = [UIColor whiteColor];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"新浪微博";
        cell.imageView.image = [UIImage imageNamed:@"weibo_logo"];
    } else if(indexPath.row == 1){
        cell.textLabel.text = @"微信好友";
        cell.imageView.image = [UIImage imageNamed:@"weixin_icon"];
    } else if(indexPath.row == 2){
        cell.textLabel.text = @"微信朋友圈";
        cell.imageView.image = [UIImage imageNamed:@"weixin_timeline_icon"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0){
        [_delegate shareToSinaWeibo];
    } else if(indexPath.row == 1){
        [_delegate shareToWeixinContact];
    } else if(indexPath.row == 2){
        [_delegate shareToWeixinTimeline];
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
