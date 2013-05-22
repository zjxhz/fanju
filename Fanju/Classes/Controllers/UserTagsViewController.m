//
//  UserTagsViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/25/13.
//
//

#import "UserTagsViewController.h"
#import "Authentication.h"
#import "NewTagViewController.h"
#import "SVProgressHUD.h"
#import "DictHelper.h"
#import "InfoUtil.h"
#import "UserTagDataSource.h"

@interface UserTagsViewController (){
    NSMutableArray* _selectedTags;//selected, including all tags from the myself, which may not be visible if they are not tags of current user
    BOOL _tagCountBeforeDelete;
}

@end

@implementation UserTagsViewController

- (id)initWithUser:(User*)user{
    if(self = [super initWithStyle:UITableViewStylePlain]){
        self.user = user;
        _selectedTags = [NSMutableArray array];
        if (![self isViewForMyself]) {
            [_selectedTags addObjectsFromArray:[Authentication sharedInstance].currentUser.tags];
        }
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = [self isViewForMyself] ? @"您的爱好" : @"选择共同爱好";
    NSString* rightBarButtonTitle = [self isViewForMyself] ? @"编辑" : @"保存";
    SEL action = [self isViewForMyself] ? @selector(editTable:) : @selector(saveSeleted:);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:rightBarButtonTitle style:UIBarButtonItemStyleBordered target:self action:action];
    [self loadTags];    
}

-(BOOL)isViewForMyself{
    return [[Authentication sharedInstance].currentUser isEqual:_user];
}

-(void)loadTags{
    UserTagDataSource* ds = [[UserTagDataSource alloc] initWithItems:[NSMutableArray arrayWithArray:_user.tags]];
    if ([ self isViewForMyself]) {
        [ds.items insertObject:@"加更多爱好" atIndex:0];
    }
    self.dataSource = ds;
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)editTable:(id)sender{
    TTListDataSource* ds = self.dataSource;
    if (self.tableView.editing) {
        self.tableView.editing = NO;
        self.navigationItem.rightBarButtonItem.title = @"编辑";
        if (ds.items.count - 1 < _tagCountBeforeDelete) {
            _tagCountBeforeDelete = ds.items.count - 1;
            [self saveTags];
        }
    } else {
        _tagCountBeforeDelete = ds.items.count - 1;
        self.tableView.editing = YES;
        self.navigationItem.rightBarButtonItem.title = @"完成";
    }
}

-(void)saveSeleted:(id)sender{
    [SVProgressHUD showWithStatus:@"正在保存设置…" maskType:SVProgressHUDMaskTypeBlack];
    [self saveTags];
}

-(void)saveTags{
    UserProfile* user = [Authentication sharedInstance].currentUser;
    NSArray* tagsToSave = [self tagsToSave];
    NSString *strTags = [UserTag tagsToString:tagsToSave];
    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"tags" andValue:strTags]];
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/tags/?format=json", HTTPS, EOHOST, user.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                DDLogVerbose(@"tags saved");
                                                [SVProgressHUD dismissWithSuccess:@"保存成功。"];
                                                [user.tags removeAllObjects];
                                                [user.tags addObjectsFromArray:tagsToSave];
                                                [self.tagDelegate tagsSaved:tagsToSave forUser:user];
                                            } else {
                                                [InfoUtil showError:obj];
                                            }
                                        } failure:^{
                                            DDLogError(@"failed to save settings");
                                            [SVProgressHUD dismissWithError:@"保存失败，请退出此页面重新刷新再试"];
                                        }];
}

-(NSArray*)tagsToSave{
    TTListDataSource *ds = self.dataSource;
    if ([self isViewForMyself]) {
        NSMutableArray* all = [ds.items mutableCopy];
        [all removeObjectAtIndex:0];
        return all;
    } else {
        return _selectedTags;
    }
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TTListDataSource* ds = self.dataSource;
    id object = [ds tableView:self.tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[UserTag class]]) {
        UserTag* tag = object;
        if (![self isViewForMyself] && [_selectedTags containsObject:tag]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else if ([object isKindOfClass:[NSString class]]){
        cell.textLabel.text = object;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self isViewForMyself] && indexPath.row == 0) {
        [self showAllTags];
    } else {
        UserTag* tag = [self.dataSource tableView:self.tableView objectForRowAtIndexPath:indexPath];
        if ([_selectedTags containsObject:tag]) {
            [_selectedTags removeObject:tag];
        } else {
            [_selectedTags addObject:tag];
        }
        [self refresh];
    }
}

-(void)showAllTags{
    NewTagViewController* tagC = [[NewTagViewController alloc] initWithStyle:UITableViewStyleGrouped];
    tagC.user = self.user;
    tagC.delegate = self;
    [self.navigationController pushViewController:tagC animated:YES];
}

#pragma mark TagViewControllerDelegate
-(void)tagsSaved:(NSArray*)newTags forUser:(UserProfile*)user{
    [self loadTags];
}
@end
