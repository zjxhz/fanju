//
//  NewTagViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/23/13.
//
//

#import "NewTagViewController.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "Const.h"
#import "SVProgressHUD.h"
#import "DictHelper.h"
#import "InfoUtil.h"
#import "LoadMoreTableItem.h"
#import "WidgetFactory.h"
#import "Tag.h"
#import "TagSelectionDataSource.h"
#import "TagSelectionItem.h"
#import "InfoUtil.h"

const NSInteger MOST_POPULAR_TAG_COUNT = 5;
#define AUTO_COMPLETE_Y 55
@interface NewTagViewController (){
    NSMutableArray *_tags;
    LoadMoreTableItem *_loadMore;
    UISearchBar* _searchBar;
    TagAutocompleteTableView* _autoComplete;
    NSMutableArray *_newTags;
}

@end

@implementation NewTagViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadTags];
    
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"添加兴趣"];
    self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] backButtonWithTarget:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"保存" target:self action:@selector(saveTags)];
    self.tableView.backgroundColor = RGBCOLOR(0xF2, 0xF2, 0xF2);
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    _searchBar.placeholder = @"搜索兴趣";
    _searchBar.backgroundImage = [[UIImage imageNamed:@"searchbar_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 29, 22, 30)];
    _searchBar.delegate = self;
    for(UIView *subView in _searchBar.subviews) {
        if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
            UITextField *t = (UITextField *)subView;
            [t setKeyboardAppearance: UIKeyboardAppearanceAlert];
            t.returnKeyType = UIReturnKeyDone;
            t.delegate = self;
            break;
        }
    }
    
    self.tableView.tableHeaderView = _searchBar;
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    reg.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:reg];
    _autoComplete = [[TagAutocompleteTableView alloc] initWithFrame:CGRectMake(0, AUTO_COMPLETE_Y, 320, 240) style:UITableViewStylePlain];
    _autoComplete.hidden = YES;
    _autoComplete.autocompleteDelegate = self;
    [self.view addSubview:_autoComplete];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    CGFloat autoCompleteHeight = self.view.frame.size.height - AUTO_COMPLETE_Y;
    _autoComplete.frame = CGRectMake(0, AUTO_COMPLETE_Y, 320, autoCompleteHeight);
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

-(void)goBack{
    if ([self.dataSource isKindOfClass:[TTSectionedDataSource class]]) {//NO if tags not loaded
        NSSet* selectedTagSet = [[NSSet alloc] initWithArray:[self selectedTags]];
        if (![_user.tags isEqual:selectedTagSet]) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"兴趣爱好已经修改，是否保存" delegate:self cancelButtonTitle:@"不保存" otherButtonTitles:@"保存", nil];
            [alert show];
            return;
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)loadTags{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"usertag/" parameters:@{@"limit":@"0"} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        _tags = [mappingResult.array mutableCopy];
        _newTags = [NSMutableArray array];
        _autoComplete.tags = _tags;
        NSArray* items = @[[self tagsOfSection:0], [self tagsOfSection:1]];
        NSArray* sections = @[@"最热门", @"其它"];
        TagSelectionDataSource *ds =  [[TagSelectionDataSource alloc] initWithItems:items sections:sections];
        self.dataSource = ds;
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        DDLogError(@"failed to fetch user tags.");
        [SVProgressHUD showErrorWithStatus:@"获取数据失败"];
    }];
}

-(NSArray*)tagsOfSection:(NSUInteger)section{
    if (section == 0) {
        NSMutableArray* items0 = [NSMutableArray arrayWithCapacity:5];
        for (int i = 0; i < 5; i++) {
            TagSelectionItem* item = [self tagSelectionItem:_tags[i]];
            [items0 addObject:item];
        }
        return items0;
    } else {
        NSMutableArray* items1 = [NSMutableArray arrayWithCapacity:5];
        for (int i = 5; i < _tags.count; i++) {
            TagSelectionItem* item = [self tagSelectionItem:_tags[i]];
            [items1 addObject:item];
        }
        return items1;
    }
}

-(TagSelectionItem*)tagSelectionItem:(Tag*)tag{
    TagSelectionItem* item = [[TagSelectionItem alloc] init];
    item.tag = tag;
    item.selected = [_user.tags containsObject:tag];
    return item;
}


- (id<UITableViewDelegate>)createDelegate{
    return self;
}


- (void)save:(id)sender
{    
//    if (_selectedTags.count < 3) {
//        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请至少选择3项您感兴趣的内容" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
//        [a show];
//        return;
//    }
    [SVProgressHUD showWithStatus:@"正在保存设置…" maskType:SVProgressHUDMaskTypeBlack];
    [self saveTags];
}

-(NSArray*)selectedTags{
    NSMutableArray* selectedTags = [NSMutableArray array];
    TagSelectionDataSource *ds = self.dataSource;
    for (NSArray* sectionedItems in ds.items) {
        for (TagSelectionItem *item in sectionedItems) {
            if (item.selected) {
                [selectedTags addObject:[item isSaved] ? item.tag : item.tagName];
            }
        }
    }
    return selectedTags;
}
-(void)saveTags{
    NSArray* selectedTags = [self selectedTags];
    if (selectedTags.count < 3) {
        [InfoUtil showAlert:@"请至少选择3个标签"];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"保存中…" maskType:SVProgressHUDMaskTypeBlack];

    NSString *strTags = [TagService tagsToString:selectedTags];
    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"tags" andValue:strTags]];
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%@/tags/?format=json", HTTPS, EOHOST, _user.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSString* resultStatus = [obj objectForKey:@"status"];
                                            if ([resultStatus isEqualToString:@"OK"]) {
                                                DDLogVerbose(@"tags saved");
                                                [self reloadUserTags];
//                                                [SVProgressHUD showSuccessWithStatus:@"保存成功。"];
//                                                
//                                                
//                                                [_user removeTags:_user.tags];
//                                                
//                                                
//                                                
//                                                NSMutableSet* tags = [_user.tags mutableCopy];
//                                                NSSet* existingTags = [[NSSet alloc] initWithArray:selectedTags];
//                                                [tags minusSet:existingTags];
//                                                for (Tag* tag in tags) {
//                                                    DDLogVerbose(@"removing tag %@", tag.name);
//                                                    [_user removeTagsObject:tag];
//                                                }
//                                                NSMutableSet* addedTags = [existingTags mutableCopy] ;
//                                                [addedTags minusSet:_user.tags];
//                                                for (Tag* tag in addedTags){
//                                                    [_user addTagsObject:tag];
//                                                    DDLogVerbose(@"adding tag %@", tag.name);
//                                                }
//                                                NSManagedObjectContext* contex = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
//                                                NSError* error;
//                                                if(![contex saveToPersistentStore:&error]){
//                                                    DDLogError(@"failed to save after saving tags: %@", error);
//                                                }
//                                                [self.delegate tagsSaved:selectedTags forUser:_user];
                                            } else {
                                                DDLogError(@"failed to set tags with error: %@",resultStatus);
                                                [SVProgressHUD showErrorWithStatus:resultStatus];
                                            }
                                        } failure:^{
                                            DDLogError(@"failed to save settings");
                                            [SVProgressHUD showErrorWithStatus:@"保存失败"];
                                        }];
}

-(void)reloadUserTags{
    RKObjectManager* manager = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"user/%@/tags/", _user.uID];
    [manager getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        DDLogInfo(@"user tags reloaded");
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
        [_user removeTags:_user.tags];
        [_user addTags:[[NSSet alloc] initWithArray:mappingResult.array]];
        NSManagedObjectContext* contex = manager.managedObjectStore.mainQueueManagedObjectContext;
        NSError* error;
        if(![contex saveToPersistentStore:&error]){
            DDLogError(@"failed to save after saving tags: %@", error);
        }
        [self.delegate tagsSaved:[self selectedTags] forUser:_user];
        [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(goBackLater) userInfo:nil repeats:NO];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"已保存到服务器，但无法同步，请稍后再试"];
        DDLogError(@"failed to reload tags for user: %@", error);
    }];
    
}

-(void)goBackLater{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TagSelectionDataSource* ds = self.dataSource;
    id object = [ds tableView:self.tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[TagSelectionItem class]]){
        TagSelectionItem* item = object;
        item.selected = !item.selected;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    view.backgroundColor = RGBCOLOR(0xE3, 0xE3, 0xE3);
    NSString* title = section == 0 ? @"热门" : @"其他";
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 30)];
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.text = title;
    titleLabel.textColor = RGBCOLOR(0x7D, 0x7C, 0x7C);
    titleLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:titleLabel];
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

-(void)viewTapped:(UITapGestureRecognizer*)sender{
    if ([_searchBar isFirstResponder]) {
        [_searchBar resignFirstResponder];
    }
}

#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}

#pragma mark UISearchBarDelegate
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if (searchText.length > 0) {
        _autoComplete.hidden = NO;
        [_autoComplete searchText:searchText];
    } else {
        _autoComplete.hidden = YES;
    }
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [searchBar setShowsCancelButton:YES animated:YES];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
        [searchBar setShowsCancelButton:NO animated:YES];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
    [searchBar setText:@""];
    _autoComplete.hidden = YES;    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}
#pragma mark TagAutocompleteDelegate
-(void)tagSelected:(NSString *)tagName{
    NSIndexPath* indexPath = [self indexPathForTagName:tagName];
    _autoComplete.hidden = YES;
    [_searchBar setText:@""];
    
    TagSelectionItem* item = [self findItemForTagName:tagName];
    item.selected = YES;
   
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已选择了 %@", tagName]];
}

-(NSIndexPath*)indexPathForTagName:(NSString*)tagName{
    TagSelectionDataSource* ds = self.dataSource;
    TagSelectionItem* item = [self findItemForTagName:tagName];
    return [ds tableView:self.tableView indexPathForObject:item];
}

-(void)newTagSelected:(NSString*)tagName{
    _autoComplete.hidden = YES;
    [_newTags addObject:tagName];
    [_tags addObject:tagName];
    _autoComplete.tags = _tags;
    TagSelectionItem* item = [[TagSelectionItem alloc] init];
    item.tagName = tagName;
    item.selected = YES;
    
    TagSelectionDataSource* ds = self.dataSource;
    NSMutableArray* items1 = [ds.items objectAtIndex:1];
    [items1 addObject:item];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:items1.count - 1 inSection:1];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已创建并选择了 %@", tagName]];
    
//    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"create_tag" andValue:tagName]];
//    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%@/tags/", HTTPS, EOHOST, _user.uID];
//    [[NetworkHandler getHandler] requestFromURL:requestStr
//                                         method:POST
//                                     parameters:params
//                                    cachePolicy:TTURLRequestCachePolicyNone
//                                        success:^(id obj) {
//                                            NSString* resultStatus = [obj objectForKey:@"status"];
//                                            if ([resultStatus isEqualToString:@"OK"]) {
//                                                DDLogVerbose(@"tags created");
//                                                NSManagedObjectContext* contex = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
//                                                Tag* tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:contex];
//                                                tag.name = tagName;
//                                                tag.tID = [obj objectForKey:@"id"];
//                                                NSError* error;
//                                                if(![contex saveToPersistentStore:&error]){
//                                                    DDLogError(@"failed to save a new tag:%@, %@", tagName, error);
//                                                } else {
//                                                    [_tags addObject:tag];
//                                                    _autoComplete.tags = _tags;
//                                                    TagSelectionItem* item = [self tagSelectionItem:tag];
//                                                    item.selected = YES;
//                                                    TagSelectionDataSource* ds = self.dataSource;
//                                                    NSMutableArray* items1 = [ds.items objectAtIndex:1];
//                                                    [items1 addObject:item];
//                                                    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:items1.count - 1 inSection:1];
//                                                    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
//                                                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已创建并选择了 %@", tag.name]];
//                                                }
//                                                
//                                            } else {
//                                                DDLogError(@"failed to set tags with error: %@",resultStatus);
//                                                [SVProgressHUD showErrorWithStatus:resultStatus];
//                                            }
//                                        } failure:^{
//                                            DDLogError(@"failed to save settings");
//                                            [SVProgressHUD showErrorWithStatus:@"保存失败"];
//                                        }];
       
}

-(TagSelectionItem*)findItemForTagName:(NSString*)tagName{
    TagSelectionDataSource *ds = self.dataSource;
    for (NSArray* sectionedItems in ds.items) {
        for (TagSelectionItem *item in sectionedItems) {
            if (([item isSaved] && [item.tag.name isEqual:tagName]) || [item.tagName isEqual:tagName]) {
                return item;
            } 
        }
    }
    return nil;
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [_searchBar resignFirstResponder];
    return YES;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [self saveTags];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
