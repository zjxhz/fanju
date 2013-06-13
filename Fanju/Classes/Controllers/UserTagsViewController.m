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
#import "WidgetFactory.h"

@interface UserTagsViewController (){
    BOOL _tagCountBeforeDelete;
}

@end

@implementation UserTagsViewController

- (id)initWithUser:(User*)user{
    if(self = [super initWithStyle:UITableViewStylePlain]){
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"我的兴趣"];
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"编辑" target:self action:@selector(editTable:)];
    self.tableView.backgroundColor = RGBCOLOR(0xF5, 0xF5, 0xF5);
    [self loadTags];    
}


-(void)loadTags{
    UserTagDataSource* ds = [[UserTagDataSource alloc] initWithItems:[_user.tags allObjects]];
    [ds.items insertObject:@"添加更多兴趣" atIndex:0];
    self.dataSource = ds;
}

- (id<UITableViewDelegate>)createDelegate {
    return self;
}

-(void)editTable:(id)sender{
    TTListDataSource* ds = self.dataSource;
    UIBarButtonItem* item =  self.navigationItem.rightBarButtonItem;
    UIButton* button = (UIButton*)item.customView;
    if (self.tableView.editing) {
        self.tableView.editing = NO;
        [button setTitle:@"编辑" forState:UIControlStateNormal];
        //no need to save as it is already saved when it is deleted
//        if (ds.items.count - 1 < _tagCountBeforeDelete) {
//            _tagCountBeforeDelete = ds.items.count - 1;
//            [self saveTags];
//        }
    } else {
        _tagCountBeforeDelete = ds.items.count - 1;
        self.tableView.editing = YES;
        [button setTitle:@"完成" forState:UIControlStateNormal];
    }
}

-(void)saveTags{
//    NSArray* tagsToSave = [self tagsToSave];
//    NSString *strTags = [TagService tagsToString:tagsToSave];
//    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"tags" andValue:strTags]];
//    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%@/tags/?format=json", HTTPS, EOHOST, _user.uID];
//    [[NetworkHandler getHandler] requestFromURL:requestStr
//                                         method:POST
//                                     parameters:params
//                                    cachePolicy:TTURLRequestCachePolicyNone
//                                        success:^(id obj) {
//                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
//                                                DDLogInfo(@"tags saved");
//                                                [SVProgressHUD showSuccessWithStatus:@"保存成功"];
//                                                NSMutableSet* tags = [_user.tags mutableCopy];
//                                                NSSet* existingTags = [[NSSet alloc] initWithArray:tagsToSave];
//                                                [tags minusSet:existingTags];
//                                                for (Tag* tag in tags) {
//                                                    [_user removeTagsObject:tag];
//                                                }
//                                                NSManagedObjectContext* contex = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
//                                                NSError* error;
//                                                if(![contex saveToPersistentStore:&error]){
//                                                    DDLogError(@"failed to save after saving tags: %@", error);
//                                                }
//                                                [self.tagDelegate tagsSaved:tagsToSave forUser:_user];
//                                            } else {
//                                                [InfoUtil showError:obj];
//                                            }
//                                        } failure:^{
//                                            DDLogError(@"failed to save settings");
//                                            [SVProgressHUD showErrorWithStatus:@"保存失败，请退出此页面重新刷新再试"];
//                                        }];
}

-(NSArray*)tagsToSave{
    TTListDataSource *ds = self.dataSource;
    NSMutableArray* all = [ds.items mutableCopy];
    [all removeObjectAtIndex:0];
    return all;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TTListDataSource* ds = self.dataSource;
    id object = [ds tableView:self.tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[NSString class]]){
        cell.textLabel.text = object;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        [self showAllTags];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 53;
    }
    return 45;
}
-(void)showAllTags{
    NewTagViewController* tagC = [[NewTagViewController alloc] initWithStyle:UITableViewStylePlain];
    tagC.user = self.user;
    tagC.delegate = self;
    [self.navigationController pushViewController:tagC animated:YES];
}

#pragma mark TagViewControllerDelegate
-(void)tagsSaved:(NSArray*)newTags forUser:(UserProfile*)user{
    [self loadTags];
}
@end
