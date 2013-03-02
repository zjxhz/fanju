//
//  FeedsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedsViewController.h"
#import "AppDelegate.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "Const.h"

@interface FeedsViewController ()

@end

@implementation FeedsViewController
@synthesize profile;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void) loadView{
    [super loadView];
    AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:delegate.bgImage]; 
    self.variableHeightRows = YES;
    self.tableView.backgroundColor = [UIColor clearColor]; 
    UIView *emptyFooterToGetRidOfAdditionalSeparators = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
    emptyFooterToGetRidOfAdditionalSeparators.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:emptyFooterToGetRidOfAdditionalSeparators];
}
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    [self requestFeeds];
//    
//}
//
//
//-(void) requestFeeds{
//    NSString *requestStr = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/feeds/format=json", EOHOST, self.profile.uID];
//    [[NetworkHandler getHandler] requestFromURL:requestStr
//                                         method:GET
//                                    cachePolicy:TTURLRequestCachePolicyNone 
//                                        success:^(id obj) {                        
//                                            feeds *ds = [[CommentListDataSource alloc] init];
//                                            NSArray *comments = [obj objectForKeyInObjects];
//                                            if (comments && [comments count] > 0) {
//                                                for (NSDictionary *comment in comments) {
//                                                    UserProfile *from_person = [UserProfile profileWithData:[comment objectForKey:@"from_person"]];
//                                                    NSString* user_comment = [comment objectForKey:@"message"];
//                                                    CommentTableItem *item = [CommentTableItem itemFromUser:from_person withComment:user_comment];
//                                                    [ds.items addObject:item];
//                                                }  
//                                            } else {
//                                                [ds.items addObject:[TTTableSubtitleItem itemWithText:@"暂时还没有评论" subtitle:@"来抢沙发吧"]];
//                                            }
//                                            self.dataSource = ds;
//                                        } failure:^{
//                                            
//                                        }];
//}
//
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

@end
