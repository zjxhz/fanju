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

const NSInteger MOST_POPULAR_TAG_COUNT = 5;

@interface NewTagViewController (){
    NSMutableArray *_tags;
    NSMutableArray *_selectedTags;
    LoadMoreTableItem *_loadMore;
    UISearchBar* _searchBar;
    TagAutocompleteTableView* _autoComplete;
}

@end

@implementation NewTagViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadTags];
    self.title = @"选择感兴趣的话题";
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                  target:self
                                                                                  action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    _searchBar.delegate = self;
    
    self.tableView.tableHeaderView = _searchBar;
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    reg.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:reg];
    _autoComplete = [[TagAutocompleteTableView alloc] initWithFrame:CGRectMake(0, 55, 320, 240) style:UITableViewStylePlain];
    _autoComplete.hidden = YES;
    _autoComplete.autocompleteDelegate = self;
    [self.view addSubview:_autoComplete];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}
-(void)loadTags{
    _selectedTags = [[NSMutableArray alloc] initWithArray:_user.tags];
    NSString *baseURL = [NSString stringWithFormat:@"%@://%@/api/v1/usertag/?format=json&limit=0", HTTPS, EOHOST];
    [[NetworkHandler getHandler] requestFromURL:baseURL
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSArray *tags = [obj objectForKeyInObjects];
                                            _tags = [NSMutableArray array];

                                            for (NSDictionary *dict in tags) {
                                                UserTag *tag = [[UserTag alloc] initWithData:dict];
                                                [_tags addObject:tag];
                                            }
                                            _autoComplete.tags = _tags;
                                            NSArray* items = @[[self tagsOfSection:0], [self tagsOfSection:1]];
                                            NSArray* sections = @[@"最热门", @"其它"];
                                            TTSectionedDataSource *ds =  [TTSectionedDataSource dataSourceWithItems:items sections:sections];
                                            
                                            _loadMore = [[LoadMoreTableItem alloc] initWithResult:obj fromBaseURL:baseURL];
                                            if ([_loadMore hasMore]) {
                                                NSMutableArray* items1 = [ds.items objectAtIndex:1];
                                                [items1 addObject:_loadMore];
                                            }
                                            self.dataSource = ds;
                                        } failure:^{
                                            NSLog(@"failed to fetch user tags.");
                                            [SVProgressHUD dismissWithError:@"获取数据失败"];
                                        }];
}

-(void) loadMoreTags{
    if (![_loadMore hasMore]) {
        return;
    }
    [[NetworkHandler getHandler] requestFromURL:[_loadMore nextPageURL]
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            //load data
                                            NSDictionary* result = obj;
                                            NSArray *tags = [obj objectForKeyInObjects];
                                            TTSectionedDataSource *ds = self.dataSource;
                                            NSMutableArray * indexPaths = [NSMutableArray array];
                                            if (tags && [tags count] > 0) {
                                                for (NSDictionary *dict in tags) {
                                                    UserTag* tag = [[UserTag alloc] initWithData:dict];
                                                    [_tags addObject:tag];
                                                    _autoComplete.tags = _tags;
                                                    NSMutableArray* items1 = [ds.items objectAtIndex:1];
                                                    [items1 insertObject:tag atIndex:items1.count - 1];
                                                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:items1.count - 1 inSection:1];
                                                    [indexPaths addObject:indexPath];
                                                }
                                            }
                                            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                                            
                                            //update load more text and decide if it should be removed
                                            _loadMore.loading = NO;
                                            _loadMore.offset = [result offset];
                                            if (![_loadMore hasMore])  {
                                                NSMutableArray* items1 = [ds.items objectAtIndex:1];
                                                [items1 removeLastObject];
                                                NSArray *rowToDelete = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:(items1.count - 1) inSection:1]];
                                                [self.tableView  deleteRowsAtIndexPaths:rowToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
                                            }
                                            [self.tableView reloadData];
                                        } failure:^{
                                            NSLog(@"failed to load more followings");
#warning fail handling
                                        }];
}

-(NSArray*)tagsOfSection:(NSUInteger)section{
    if (section == 0) {
        NSMutableArray* items0 = [NSMutableArray arrayWithCapacity:5];
        for (int i = 0; i < 5; i++) {
            [items0 addObject:[_tags objectAtIndex:i]];
        }
        return items0;
    } else {
        NSMutableArray* items1 = [NSMutableArray arrayWithCapacity:5];
        for (int i = 5; i < _tags.count; i++) {
            [items1 addObject:[_tags objectAtIndex:i]];
        }
        return items1;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (id<UITableViewDelegate>)createDelegate{
    return self;
}


- (void)save:(id)sender
{
    if (_selectedTags.count < 3) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"兴趣少于3个" message:@"请至少选择3项您感兴趣的内容" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return;
    }
    [SVProgressHUD showWithStatus:@"正在保存设置…" maskType:SVProgressHUDMaskTypeBlack];
    [self saveTags];
}

-(void)saveTags{
    NSString *strTags = [UserTag tagsToString:_selectedTags];
    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"tags" andValue:strTags]];
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/tags/?format=json", HTTPS, EOHOST, _user.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                NSLog(@"tags saved");
                                                [SVProgressHUD dismissWithSuccess:@"保存成功。"];
                                                [_user.tags removeAllObjects];
                                                [_user.tags addObjectsFromArray:_selectedTags];
                                                [self.delegate tagsSaved:_selectedTags forUser:_user];
                                            } else {
                                                [InfoUtil showError:obj];
                                            }
                                        } failure:^{
                                            NSLog(@"failed to save settings");
                                            [SVProgressHUD dismissWithError:@"保存失败"];
                                        }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TTSectionedDataSource* ds = self.dataSource;
    id object = [ds tableView:self.tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[UserTag class]]){
        UserTag* tag = object;
        if ([_selectedTags containsObject:tag]) {
            [_selectedTags removeObject:tag];
        } else {
            [_selectedTags addObject:tag];
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    else if ([object isKindOfClass:[LoadMoreTableItem class]]){
        if (_loadMore.loading) {
            return;
        }
        _loadMore.loading = YES;
        [self reloadLastRow];
        [self loadMoreTags];
    }
}

-(void)reloadLastRow{
    TTSectionedDataSource* ds = self.dataSource;
    NSMutableArray* items1 = [ds.items objectAtIndex:1];
    
    NSArray *lastRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:items1.count - 1 inSection:1]];
    [self.tableView reloadRowsAtIndexPaths:lastRow withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    TTSectionedDataSource* ds = self.dataSource;
    id object = [ds tableView:self.tableView objectForRowAtIndexPath:indexPath];
    if ([object isKindOfClass:[UserTag class]]) {
        UserTag* tag = object;
        cell.textLabel.text = tag.name;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([_selectedTags containsObject:tag]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
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

#pragma mark TagAutocompleteDelegate
-(void)tagSelected:(UserTag *)tag{
    TTSectionedDataSource* ds = self.dataSource;
    _autoComplete.hidden = YES;
    NSIndexPath* indexPath = nil;
    [_searchBar setText:@""];
    if ([_tags containsObject:tag]) {
        indexPath = [ds tableView:self.tableView indexPathForObject:tag];
        if (![_selectedTags containsObject:tag]) {
            [_selectedTags addObject:tag];
        }
    } else {
        [_tags addObject:tag];
        TTSectionedDataSource* ds = self.dataSource;
        NSMutableArray* items1 = [ds.items objectAtIndex:1];
        [items1 addObject:tag];
        indexPath = [NSIndexPath indexPathForRow:items1.count - 1 inSection:1];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [_selectedTags addObject:tag];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [SVProgressHUD showInView:self.view status:[NSString stringWithFormat:@"您已选择了 %@", tag.name] networkIndicator:NO];
    [self performSelector:@selector(dismissHUD:) withObject:nil afterDelay:0.7];
}

-(void) dismissHUD:(id)object{
    [SVProgressHUD dismiss];
}
@end
