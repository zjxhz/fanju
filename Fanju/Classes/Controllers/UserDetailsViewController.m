//
//  UserDetailsViewController.m
//  Fanju
//
//  Created by Xu Huanze on 5/15/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "UserDetailsViewController.h"
#import "EditUserDetailsViewController.h"
#import "User.h"
#import "ImageUploader.h"
#import "PhotoThumbnailCell.h"
#import "UserTagsCell.h"
#import "WidgetFactory.h"
#import "UserService.h"
#import "URLService.h"
#import "DictHelper.h"
#import "NetworkHandler.h"
#import "Conversation.h"
#import "MessageService.h"
#import "XMPPChatViewController2.h"
#import "UserDetailsCell.h"
#import "PhotoTitleCell.h"
#import "PhotoThumbnailCell.h"
#import "UserInfoCell.h"
#import "UserSocialCell.h"
#import "AlbumViewController.h"
#import "SVProgressHUD.h"
#import "Authentication.h"
#import "UserTagsViewController.h"
#import "SVWebViewController.h"
#import "Relationship.h"
#import "MealDetailViewController.h"
#import "PhotoViewController.h"

#define TOOLBAR_HEIGHT 49
@interface UserDetailsViewController (){
    PhotoThumbnailCell* _photoCell;
    Photo* _selectedPhoto;
    NSInteger _selectedIndex;
    UIActionSheet* _imagePickerActions;
    UIActionSheet* _imageDeleteOrViewActions;
    UserTagsCell* _tagCell;
    UIToolbar* _toolbar;
    UIImageView* _shadowView;
    ImageUploader* _imageUploader;
    UserDetailsCell* _userDetailsCell;
    UIButton* _followButton;
    NSManagedObjectContext* _contex;
    BOOL _reloaded;
    Meal* _nextMeal;
    UITableView* _tableView;
}

@end

@implementation UserDetailsViewController
- (id)init{
    if (self = [super init]) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [self.view addSubview:_tableView];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
        _tableView.showsVerticalScrollIndicator = NO;
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _contex = store.mainQueueManagedObjectContext;
    }
    return self;
}

-(void)edit:(id)sender{
    EditUserDetailsViewController* editor = [[EditUserDetailsViewController alloc] init];
    editor.user = _user;
    //    editor.delegate = self;
    [self.navigationController pushViewController:editor animated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    UIImage* toolbarBg = [UIImage imageNamed:@"toolbar_bg"] ;
    self.toolbarItems  = [self createToolbarItems];
    [self.navigationController.toolbar setBackgroundImage:toolbarBg forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationController setToolbarHidden:NO];
    [self updateNavigationBar];
    _tableView.frame = self.view.frame;
}

-(void)buildUI{
    UIImage* toolbarShadow = [UIImage imageNamed:@"toolbar_shadow"];
    _shadowView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _shadowView.image = toolbarShadow;
    [self.view addSubview:_shadowView];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:NOTIFICATION_USER_UPDATE object:nil];
    UIImage* toolbarBg = [UIImage imageNamed:@"toolbar_bg"] ;
    
    [self.navigationController.toolbar setBackgroundImage:toolbarBg forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    [self buildUI];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self reload:nil];
    [self sendVisited];
    

    
    UIImage* toolbarShadow = [UIImage imageNamed:@"toolbar_shadow"];
    CGFloat shadowY = self.view.frame.size.height - toolbarShadow.size.height - 5;//toolbar height is 49, which is 5 higher than the default
    _shadowView.frame  = CGRectMake(0, shadowY, toolbarShadow.size.width, toolbarShadow.size.height);
    
    CGRect frame = self.view.frame;
    //    frame.size.height = self.view.frame.size.height - toolbarBg.size.height;
    _tableView.frame = frame;
    [self.view sendSubviewToBack:_tableView];
}

-(void)setUser:(User*)user{
    _user = user;
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:_user.name];
    //    [self loadComments];
    [_tableView reloadData];
}

-(void)updateTitle{
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:_user.name];
}

-(void)viewDidUnload{
    [super viewDidUnload];
}

-(void)sendVisited{
    if (![self isViewForMyself]) {
        NSString* url = [URLService absoluteApiURL:@"user/%@/visitors/", _user.uID ];
        NSString* myID = [[UserService service].loggedInUser.uID stringValue];
        NSArray* params = @[[DictHelper dictWithKey:@"visitor_id" andValue:myID]];
        [[NetworkHandler getHandler] requestFromURL:url
                                             method:POST
                                         parameters:params
                                        cachePolicy:TTURLRequestCachePolicyNone
                                            success:^(id obj) {
                                                if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                    DDLogVerbose(@"you visited %@ and s/he now knows it", _user.name);
                                                } else {
                                                    DDLogError(@"failed to tell %@ that you visited her/him", _user);
                                                }
                                            } failure:^{
                                                DDLogError(@"failed to tell %@ that you visited her/him", _user);
                                            }];
    }
}

-(void)updateNavigationBar{
    if ([self isViewForMyself]) {
        self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"编辑" target:self action:@selector(edit:)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(NSArray*) createToolbarItems{
    UIBarButtonItem* flexiSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if ([self isViewForMyself]) {
        UIBarButtonItem* profile = [self createToolbarButtonItemWithTitle:@"编辑资料" image:[UIImage imageNamed:@"tb_profile"] push_image:[UIImage imageNamed:@"tb_profile_push"] selector:@selector(edit:)];
        UIBarButtonItem* photo = [self createToolbarButtonItemWithTitle:@"修改头像" image:[UIImage imageNamed:@"tb_avatar"] push_image:[UIImage imageNamed:@"tb_photo_push"] selector:@selector(editAvatar:)];
        UIBarButtonItem* avatar = [self createToolbarButtonItemWithTitle:@"上传照片" image:[UIImage imageNamed:@"tb_photo"] push_image:[UIImage imageNamed:@"tb_profile_push"] selector:@selector(addPhoto:)];
        UIBarButtonItem* motto = [self createToolbarButtonItemWithTitle:@"修改签名" image:[UIImage imageNamed:@"tb_motto"] push_image:[UIImage imageNamed:@"tb_profile_push"] selector:@selector(editMotto:)];
        return @[profile, flexiSpace, photo, flexiSpace, avatar, flexiSpace, motto];
    } else {
        UIImage* chatBg = [UIImage imageNamed:@"toolbth1"];
        UIImage* chatBgPush = [UIImage imageNamed:@"toolbth1_push"];
        UIButton* chatButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, chatBg.size.width, chatBg.size.height)];
        [chatButton setBackgroundImage:chatBg forState:UIControlStateNormal];
        [chatButton setBackgroundImage:chatBgPush forState:UIControlStateSelected];
        [chatButton setTitle:@"和Ta聊天" forState:UIControlStateNormal];
        [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        chatButton.titleLabel.font = [UIFont systemFontOfSize:20];
        [chatButton addTarget:self action:@selector(sendMsg:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem* chatItem = [[UIBarButtonItem alloc] initWithCustomView:chatButton];
        
        UIImage* followBg = [UIImage imageNamed:@"follow"];
        _followButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, followBg.size.width, followBg.size.height)];
        [_followButton addTarget:self action:@selector(followOrNot:) forControlEvents:UIControlEventTouchUpInside];
        [self updateFollowOrNotButton];
        UIBarButtonItem* followItem = [[UIBarButtonItem alloc] initWithCustomView:_followButton];
        UIBarButtonItem* noSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        noSpace.width = -10.0;
        return @[flexiSpace, chatItem, noSpace, followItem,flexiSpace];
    }
    return nil;
}

-(UIBarButtonItem*)createToolbarButtonItemWithTitle:(NSString*)title image:(UIImage*)image push_image:(UIImage*)pimage selector:(SEL)selector{
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 47)];
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    [button setTitleColor:RGBCOLOR(50, 50, 50) forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:pimage forState:UIControlStateSelected];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    // the space between the image and text
    CGFloat spacing = 0.0;
    CGSize imageSize = button.imageView.frame.size;
    CGSize titleSize = button.titleLabel.frame.size;
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    titleSize = button.titleLabel.frame.size;
    button.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)sendMsg:(id)sender {
    User* user = [UserService service].loggedInUser;
    if (![UserService hasAvatar:user]) {
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"提示" message:@"发起会话之前，请先设置头像" delegate:self cancelButtonTitle:@"以后再说" otherButtonTitles:@"设置", nil];
        [av show];
    } else {
        Conversation* conversation = [[MessageService service] getOrCreateConversation:[UserService service].loggedInUser with:_user];
        XMPPChatViewController2* c = [[XMPPChatViewController2 alloc] initWithConversation:conversation];
        [self.navigationController pushViewController:c animated:YES];
    }
    
}

-(void) updateFollowOrNotButton{
    if ([self isViewForMyself]) {
        return;
    }
    
    UIImage* followImg = [UIImage imageNamed:@"follow"];
    UIImage* followedImg = [UIImage imageNamed:@"followed"];
    if ([[RelationshipService service] isLoggedInUserFollowing:_user]) {
        [_followButton setBackgroundImage:followedImg forState:UIControlStateNormal];
    } else {
        [_followButton setBackgroundImage:followImg forState:UIControlStateNormal];
    }
}

- (IBAction)followOrNot:(id)sender {
    if ([[RelationshipService service] isLoggedInUserFollowing:_user]){
        [self unfollow];
    } else {
        [self follow];
    }
}

-(void)unfollow{
    Relationship* r = [[RelationshipService service]relationWith:_user];
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/relationship/%@/", HTTPS, EOHOST, r.rID];
    [SVProgressHUD showWithStatus:nil maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:DELETE
                                     parameters:nil
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            [SVProgressHUD showSuccessWithStatus:@"已取消关注"];
                                            [[UserService service].loggedInUser removeFollowingsObject:r];
                                            NSError* error;
                                            if(![_contex saveToPersistentStore:&error]){
                                                DDLogError(@"failed to remove a relationship to %@", _user.username);
                                            }
                                            
                                            [self updateFollowOrNotButton];
                                            [_tableView reloadData];
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"取消关注失败"];
                                            DDLogError(@"failed to remove following");
                                        }];
}

-(void)follow{
    NSArray *params = @[[DictHelper dictWithKey:@"to_person_id" andValue:[_user.uID stringValue]] ];
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/relationship/", HTTPS, EOHOST];
    [SVProgressHUD showWithStatus:nil maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD showSuccessWithStatus:@"已关注"];
                                                Relationship* r =  [NSEntityDescription insertNewObjectForEntityForName:@"Relationship" inManagedObjectContext:_contex];
                                                r.fromPerson = [UserService service].loggedInUser;
                                                r.toPerson = _user;
                                                r.status = [NSNumber numberWithInteger:0];
                                                r.rID = [NSNumber numberWithInteger: [obj[@"id"] integerValue]];
                                                [[UserService service].loggedInUser addFollowingsObject:r];
                                                NSError* error;
                                                if(![_contex saveToPersistentStore:&error]){
                                                    DDLogError(@"failed to save a relationship to %@", _user.username);
                                                }
                                                
                                                [self updateFollowOrNotButton];
                                                [_tableView reloadData];
                                            } else {
                                                [SVProgressHUD showErrorWithStatus:@"关注失败"];
                                            }
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"关注失败"];
                                        }];
}


-(IBAction)block:(id)sender{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未实现" message:@"未实现功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [a show];
}

-(void)editMotto:(id)sender{
    SetMottoViewController* vc = [[SetMottoViewController alloc] init];
    vc.mottoDelegate = self;
    [vc setMotto:_user.motto];
    vc.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"取消" target:self action:@selector(dismissModalView:)];
    vc.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"确定" target:vc action:@selector(saveMotto:)];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nav animated:YES];
}

-(void)dismissModalView:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)editAvatar:(id)sender{
    if (!_imageUploader) {
        _imageUploader = [[ImageUploader alloc] initWithViewController:self delegate:self];
    }
    [_imageUploader uploadAvatar];
}


-(void)addPhoto:(id)sender{
    if (_user.photos.count >= 15) {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"提示" message:@"抱歉，目前最多只能上传15张照片" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return;
    }
    if (!_imageUploader) {
        _imageUploader = [[ImageUploader alloc] initWithViewController:self delegate:self];
    }
    [_imageUploader uploadPhoto];
}


-(BOOL)isViewForMyself{
    if (!_user) {
        return NO;
    }
    return [[UserService service].loggedInUser isEqual:_user];
}

-(void)showNextMeal:(id)sender{
    if (_userDetailsCell.meal) {
        MealDetailViewController* vc = [[MealDetailViewController alloc] init];
        vc.meal = _userDetailsCell.meal;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Table view data source
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
            if (_userDetailsCell) {
                return _userDetailsCell.cellHeight;
            } else {
                return 215;
            }
        case 1:
            return indexPath.row == 0 ? 31 : 70;
        case 2:
            if(_user.tags.count == 0){
                return 0;
            } else if (_tagCell) {
                return _tagCell.cellHeight;
            }
            return 36;
        case 3:
            return 88;
        case 4:
            return 66;
        default:
            return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1){
        return 2;
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        static NSString* USER_DETAILS_CELL = @"USER_DETAILS_CELL";
        cell = [_tableView dequeueReusableCellWithIdentifier:USER_DETAILS_CELL];
        BOOL recalculateHeight = NO;
        if(!cell){
            cell = [[UserDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:USER_DETAILS_CELL];
            _userDetailsCell = (UserDetailsCell*)cell;
            UIGestureRecognizer *nextMealTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showNextMeal:)];
            nextMealTap.delegate  = self;
            [_userDetailsCell.nextMealView  addGestureRecognizer:nextMealTap];
            [_userDetailsCell.nextMealButton addTarget:self action:@selector(showNextMeal:) forControlEvents:UIControlEventTouchUpInside];
            recalculateHeight = YES;
        }
        
        CGFloat originalHeight = _userDetailsCell.cellHeight;
        _userDetailsCell.user = _user;
        if (_userDetailsCell.cellHeight != originalHeight) {
            recalculateHeight = YES;
        }
        if (recalculateHeight) {
            [_tableView reloadData];
        }
    } else if(indexPath.section == 1){
        if (indexPath.row == 0) {
            NSString* CellIdentifier = @"PhotoTitleCell";
            PhotoTitleCell* photoTitleCell = [[PhotoTitleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell = photoTitleCell;
            BOOL seeMore = _user.photos.count > 4;
            photoTitleCell.seeAllButton.hidden = !seeMore;
            photoTitleCell.disclosureView.hidden = !seeMore;
        } else {
            if (!_reloaded) {
                return [[UITableViewCell alloc] initWithFrame:CGRectZero];
            }
            NSString* CellIdentifier = @"PhotoThumbnailCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            BOOL editable = [self isViewForMyself];
            cell = [[PhotoThumbnailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier withUser:_user editable:editable];
            _photoCell = (PhotoThumbnailCell*)cell;
            ((PhotoThumbnailCell*)cell).delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (indexPath.section == 2){
        NSString* CellIdentifier = @"UserTagsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        BOOL recalculateHeight = NO;
        if (cell == nil) {
            cell = [[UserTagsCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            recalculateHeight = YES;
        }
        _tagCell = (UserTagsCell* )cell;
        _tagCell.rootController = self;
        CGFloat originalHeight = _tagCell.cellHeight;
        _tagCell.tags = [_user.tags allObjects];
        if (_tagCell.cellHeight != originalHeight) {
            recalculateHeight = YES;
        }
        if (recalculateHeight) {
            [_tableView reloadData];
        }
    }  else if(indexPath.section == 3){
        NSString* CellIdentifier = @"UserInfoCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:@"UserInfoCell" bundle:nil];
            cell = (UserInfoCell*)temp.view;
        }
        UserInfoCell* infoCell = (UserInfoCell*)cell;
        infoCell.college.text = _user.college;
        infoCell.company.text = _user.workFor;
        infoCell.occupation.text = _user.occupation;
    } else if(indexPath.section == 4) {
        NSString* CellIdentifier = @"UserSocialCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            UIViewController* temp = [[UIViewController alloc] initWithNibName:@"UserSocialCell" bundle:nil];
            cell = (UserSocialCell*)temp.view;
            UserSocialCell* socialCell = (UserSocialCell*)cell;
            UIGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weiboTapped:)];
            weiboTap.delegate  = self;
            [socialCell.sina addGestureRecognizer:weiboTap];
            
            UIGestureRecognizer *qqTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(qqTapped:)];
            qqTap.delegate  = self;
//            [socialCell.qq addGestureRecognizer:qqTap];
        }
        UserSocialCell* socialCell = (UserSocialCell*)cell;
        if (_user.weiboID) {
            socialCell.sina.userInteractionEnabled = YES;
            socialCell.sina.image = [UIImage imageNamed:@"social_sina"];
        } else {
            socialCell.sina.userInteractionEnabled = NO;
            socialCell.sina.image = [UIImage imageNamed:@"social_sina_disabled"];
        }
//        socialCell.qq.userInteractionEnabled = NO;
//        socialCell.qq.image = [UIImage imageNamed:@"social_qq_disabled"];
        
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


#pragma mark PhotoThumbnailCellDelegate
-(void)addOrRequestPhoto{
    if ([self isViewForMyself]) {
        [self addPhoto:nil];
    } else {
        [self requestPhoto];
        DDLogVerbose(@"not implemented");
    }
}

-(void)requestPhoto{
    NSString* url = [URLService absoluteApiURL:@"user/%@/photo_request/", _user.uID];
    NSString* loggedInUserID = [[UserService service].loggedInUser.uID stringValue];
    NSArray* params = @[[DictHelper dictWithKey:@"photo_requester_id" andValue:loggedInUserID]];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:url method:POST parameters:params cachePolicy:TTURLRequestCachePolicyNone success:^(id obj) {
        [SVProgressHUD showSuccessWithStatus:@"请求已发送"];
    } failure:^{
        [SVProgressHUD showErrorWithStatus:@"请求失败，请稍候再试"];
    }];
}

-(void) showUsrPhotosAtIndex:(NSInteger)index{
    PhotoViewController *pvc = [[PhotoViewController alloc] initWithUser:_user atIndex:index];
    pvc.title = @"照片";
    [self.navigationController pushViewController:pvc animated:YES];
}

-(void) didSelectUserPhoto:(Photo*)photo atIndex:(NSInteger)index{
    if ([self isViewForMyself]) {
        if (!_imageDeleteOrViewActions) {
            _imageDeleteOrViewActions = [[UIActionSheet alloc] initWithTitle:@"选择一个操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"查看", nil];
        }
        _selectedPhoto = photo;
        _selectedIndex = index;
        [_imageDeleteOrViewActions showFromToolbar:self.navigationController.toolbar];
    } else {
        [self showUsrPhotosAtIndex:index];
    }
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1 && indexPath.row == 0) {
        if (_user.photos.count > 4) {
            AlbumViewController* vc = [[AlbumViewController alloc] init];
            vc.user = _user;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }else if (indexPath.section == 2){
        [self showAllTags];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self isViewForMyself] && indexPath.section == 2) {
        cell.contentView.userInteractionEnabled = NO;
    }
}
#pragma mark UserDetailSaveDelegate
-(void)userProfileUpdated:(User*)user{
    [self setUser:user];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark CellTextEditorDelegate
-(void)valueSaved:(NSString *)value{
    _user.motto = value;
    [_tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
    NSDictionary* paramDict = @{@"motto": value};
    NSString* url = [URLService absoluteApiURL:@"user/%@/", _user.uID];
    [[NetworkHandler getHandler] sendJSonRequest:url
                                          method:PATCH
                                      jsonObject:paramDict
                                         success:^(id obj) {
                                             DDLogVerbose(@"motto updated");
                                         } failure:^{
                                             DDLogError(@"failed to update motto to %@", value);
                                             [SVProgressHUD showErrorWithStatus:@"更新签名失败"];
                                         }];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (_imageDeleteOrViewActions == actionSheet) {
        switch (buttonIndex) {
            case 0://delete
                [SVProgressHUD showWithStatus:@"正在删除……"];
                [self deleteUserPhoto:_selectedPhoto];
                break;
            case 1: //view
                [self showUserPhotoAsync];
                break;
            default:
                break;
        }
    }
}

-(void)showUserPhotoAsync{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showUsrPhotosAtIndex:_selectedIndex];
    });
}
-(void)deleteUserPhoto:(Photo*)photo{
    RKObjectManager* om = [RKObjectManager sharedManager];
    NSString* path = [NSString stringWithFormat:@"userphoto/%@/", photo.pID];
    [_user removePhotosObject:photo];
    [_contex saveToPersistentStore:nil];//delete locally first, and hope that delete will success remotely as well
    [om deleteObject:nil path:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [SVProgressHUD showSuccessWithStatus:@"删除成功"];
        [_tableView reloadData];
        DDLogInfo(@"user photo delete.");
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"删除失败"];
    }];
}

-(void)showAllTags{
    UserTagsViewController* utvc = [[UserTagsViewController alloc] initWithUser:_user];
    utvc.tagDelegate = self;
    [self.navigationController pushViewController:utvc animated:YES];
}

-(void)userUpdated:(NSNotification*)notif{
    User* user = notif.object;
    [self setUser:user];
}


#pragma mark -
#pragma mark PullRefreshTableViewController
-(void)reload:(id)sender{
    [[UserService service] fetchUserWithID:[_user.uID stringValue] success:^(User* user) {
        _reloaded = YES;
        [self setUser:user];
    } failure:^{
        DDLogError(@"failed to refresh user info");
    }];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)weiboTapped:(id)sender{
    if (!_user.weiboID) {
        UIAlertView* alter = [[UIAlertView alloc] initWithTitle:@"未绑定微博" message:@"该用户未绑定微博账号" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alter show];
        return;
    }
    SVWebViewController* weiboVC = [[SVWebViewController alloc]initWithAddress:[NSString stringWithFormat:@"http://m.weibo.cn/u/%@", _user.weiboID]];
    [self.navigationController pushViewController:weiboVC animated:YES];
}


#pragma mark TagViewControllerDelegate
-(void)tagsSaved:(NSArray*)newTags forUser:(UserProfile*)user{
    [_tableView reloadData];
}

#pragma mark ImageUploaderDelegate
-(void)didUploadPhoto:(Photo *)photo image:(UIImage *)image{
    [_photoCell addUploadedPhoto:photo withLocalImage:image];
    [_tableView reloadData];
    [_photoCell scrollToRight];
}
-(void)didFailUploadPhoto:(UIImage*)image{
    DDLogWarn(@"failed to upload photo");
}
-(void)didUploadAvatar:(UIImage*)image withData:(NSDictionary *)data{
    _user.avatar  = [data objectForKey:@"avatar"];
    _userDetailsCell.avatar.image = image;
    
    [_userDetailsCell.avatar setPathToNetworkImage:[URLService absoluteURL:_user.avatar]];
    [_tableView reloadData];
}

-(void)didFailUploadAvatar:(UIImage*)image{
    DDLogWarn(@"failed to upload avatar");
}

-(void)didUploadBackground:(UIImage*)image withData:(NSDictionary *)data{
    _user.backgroundImage  = [data objectForKey:@"background_image"];
    _userDetailsCell.backgroundImageView.image = image;
    
    [_userDetailsCell.avatar setPathToNetworkImage:[URLService absoluteURL:_user.avatar]];
    [_tableView reloadData];
}

-(void)didFailUploadBackground:(UIImage*)image{
    DDLogWarn(@"failed to upload background image");
}

#pragma mark SetMottoDelegate
-(void)mottoDidSet:(NSString*)motto{
    NSMutableDictionary *dict = [@{@"motto":motto} mutableCopy];
    [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%@/", HTTPS, EOHOST, _user.uID]
                                          method:PATCH
                                      jsonObject:dict
                                         success:^(id obj) {
                                             DDLogInfo(@"motto updated");
                                             _user.motto = motto;
                                             NSError* error;
                                             if(![_contex saveToPersistentStore:&error]){
                                                 DDLogError(@"failed to save motto to core data with error: %@", error);
                                             }
                                             [_tableView reloadData];
                                             [self dismissViewControllerAnimated:YES completion:^{}];
                                         } failure:^{
                                             [self dismissViewControllerAnimated:YES completion:^{}];
                                             DDLogError(@"faile to save user info");
                                         }];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UserDetailsViewController* vc = [[UserDetailsViewController alloc] init];
            vc.user = [UserService service].loggedInUser;
            [self.navigationController pushViewController:vc animated:YES];
        });
    }
}
#pragma mark UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat offset = scrollView.contentOffset.y;
    CGRect frame = _userDetailsCell.backgroundImageView.frame;
    frame.origin.y = offset;
    frame.size.height = 149 - offset;
    _userDetailsCell.backgroundImageView.frame = frame;
}
@end
