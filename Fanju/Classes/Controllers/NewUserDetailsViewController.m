//
//  NewUserDetailsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewUserDetailsViewController.h"
#import "UserTagsCell.h"
#import "PhotoThumbnailCell.h"
#import "CommentTableItemCell.h"
#import "Const.h"
#import "NetworkHandler.h"
#import "NSDictionary+ParseHelper.h"
#import "CommentTableItem.h"
#import "OrderInfo.h"
#import "DateUtil.h"
#import "DistanceUtil.h"
#import "Authentication.h"
#import "UIImage+Utilities.h"
#import "SVProgressHUD.h"
#import "PhotoViewController.h"
#import "MBProgressHUD.h"
#import "XMPPChatViewController2.h"
#import "SVWebViewController.h"
#import "UserTagsViewController.h"
#import "NINetworkImageView.h"
#import "DictHelper.h"

#define TAG_MSG @"发消息"
#define TAG_COMMENT @"发评论"

@interface NewUserDetailsViewController (){
    NSArray* _sections;
    BOOL _loadingComments;
    NSMutableArray* _commentItems;
    PhotoThumbnailCell* _photoCell;
    UserPhoto* _selectedPhoto;
    NSInteger _selectedIndex;
    NSArray* _allPhotos;
    PhotoUploadingOperation _operation;
    UIActionSheet* _imagePickerActions;
    UIActionSheet* _imageDeleteOrViewActions;
    MBProgressHUD* _hud;
    
}
@property(nonatomic, weak) IBOutlet UITableViewCell* userDetailsCell;
@property(nonatomic, weak) IBOutlet UILabel* nextMealLabel;
@property(nonatomic, weak) IBOutlet UILabel* mottoLabel;
@property(weak, nonatomic) IBOutlet UILabel* nextMealTimeLabel;
@property(nonatomic, weak) IBOutlet UILabel* age;
@property(nonatomic, weak) IBOutlet UIImageView* gender;
@property(nonatomic, weak) IBOutlet UILabel* constellation;
@property(nonatomic, weak) IBOutlet UILabel* distanceAndUpdatedAt;
@property(nonatomic, weak) IBOutlet NINetworkImageView* photoView;
@property(nonatomic, weak) IBOutlet UIView* nextMealFrame;
@property(nonatomic, weak) IBOutlet UIView* restFrame;//frame for the rest other than next meal
@property(nonatomic, strong) IBOutlet UITabBar* tabBar;
@end

@implementation NewUserDetailsViewController
@synthesize userDetailsCell = _userDetailsCell;
@synthesize nextMealLabel = _nextMealLabel;
@synthesize mottoLabel = _mottoLabel;
@synthesize nextMealTimeLabel = _nextMealTimeLabel, age = _age, gender = _gender, constellation = _constellation, distanceAndUpdatedAt = _distanceAndUpdatedAt, photoView = _photoView;
@synthesize user = _user;

- (id)initWithStyle:(UITableViewStyle)style{
    if (self = [super initWithStyle:style]) {
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        _sections = @[@"", @"兴趣爱好（%d）", @"照片", @"资料", @"社交网络", @"饭友的评论"];
    }
    return self;
}

-(void)edit:(id)sender{
    UserMoreDetailViewController* more = [[UserMoreDetailViewController alloc] initWithStyle:UITableViewStyleGrouped editable:YES];
    more.profile = _user;
    more.delegate = self;
    [self.navigationController pushViewController:more animated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    self.toolbarItems = [self createToolbarItems];
    [self updateFollowOrNotButton];
//    [self loadComments];
    [self.tableView setFrame:CGRectMake(0, 0, 320, 200)];
    self.tabBar.frame = CGRectMake(0, 300, 320, 49);
    [self.view sendSubviewToBack:self.tableView];
    [self updateNavigationBar];
}

-(void)setUser:(UserProfile *)user{
    _user = user;
    self.title = _user.name;
    [self loadComments];
    [self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self reload:YES];
    [self sendVisited];
}


-(void)sendVisited{
    if (![self isViewForMyself]) {
        int myID = [Authentication sharedInstance].currentUser.uID;
        NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/visitors/", HTTPS, EOHOST, _user.uID];
        NSArray* params = @[[DictHelper dictWithKey:@"visitor_id" andValue:[NSString stringWithFormat:@"%d", myID]]];
        [[NetworkHandler getHandler] requestFromURL:url
                                             method:POST
                                         parameters:params
                                        cachePolicy:TTURLRequestCachePolicyNone
                                            success:^(id obj) {
                                                if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                    NSLog(@"you visited %@ and s/he now knows it", _user);
                                                } else {
                                                    NSLog(@"failed to tell %@ that you visited her/him", _user);
                                                }
                                            } failure:^{
                                                NSLog(@"failed to tell %@ that you visited her/him", _user);
                                            }];
    }
}

// what we have is just a username here, so query the user info from network first
-(void)setUsername:(NSString*)username{
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/user/?format=json&user__username=%@", EOHOST, username];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSArray *users = [obj objectForKeyInObjects];
                                            if (users.count == 1) {
                                                UserProfile *user = [UserProfile profileWithData:[users objectAtIndex:0]];
                                                [self setUser:user];
                                                _photoCell.user = user;
                                            } else {
                                                [SVProgressHUD dismissWithError:@"获取数据失败"];
                                            }
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"获取数据失败"];
                                        }];
}

-(void)updateNavigationBar{
    if ([self isViewForMyself]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
}


-(NSArray*) createToolbarItems{
    NSMutableArray* items = [NSMutableArray array];
    if ([self isViewForMyself]) {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"修改资料" style:UIBarButtonItemStyleBordered target:self action:@selector(edit:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"修改头像" style:UIBarButtonItemStyleBordered target:self action:@selector(editAvatar:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"上传照片" style:UIBarButtonItemStyleBordered target:self action:@selector(addPhoto:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"修改签名" style:UIBarButtonItemStyleBordered target:self action:@selector(editMotto:)]];
    } else {
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"评论" style:UIBarButtonItemStyleBordered target:self action:@selector(comment:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"私聊" style:UIBarButtonItemStyleBordered target:self action:@selector(sendMsg:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"添加关注" style:UIBarButtonItemStyleBordered target:self action:@selector(followOrNot:)]];
        [items addObject:[[UIBarButtonItem alloc] initWithTitle:@"拉黑举报" style:UIBarButtonItemStyleBordered target:self action:@selector(block:)]];
    }
    return items;
    
}

-(void)comment:(id)sender{
    TTPostController* controller = [[TTPostController alloc] init];
    controller.delegate = self;
    controller.title = TAG_COMMENT;
    [controller showInView:self.view animated:YES];
}

- (void)sendMsg:(id)sender {
    XMPPChatViewController2* c = [[XMPPChatViewController2 alloc] initWithUserChatTo:_user.jabberID];
    [self.navigationController pushViewController:c animated:YES];
}

-(void) updateFollowOrNotButton{
    if ([self isViewForMyself]) {
        return;
    }
    UIBarButtonItem *item = [self.toolbarItems objectAtIndex:2];
    if ([[Authentication sharedInstance].currentUser isFollowing:_user]) {
        item.title = @"取消关注";
    } else {
        item.title = @"关注";
    }
}

- (IBAction)followOrNot:(id)sender {
    if ([[Authentication sharedInstance].currentUser isFollowing:_user]){
        [self unfollow];
    } else {
        [self follow];
    }
}

-(void)unfollow{
    int myID = [[Authentication sharedInstance] currentUser].uID;
    int userIdToBeUnfollowed = _user.uID;
    NSArray *params = [NSArray array];
    http_method_t method = DELETE;
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/%d/", HTTPS, EOHOST, myID, userIdToBeUnfollowed];
    
    [SVProgressHUD showWithStatus:@"正在取消关注……" maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:method
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD dismissWithSuccess:@"取消关注成功！" afterDelay:1];
                                                NSString* unfollowedUID = [NSString stringWithFormat:@"%d",userIdToBeUnfollowed];
                                                [[[Authentication sharedInstance] currentUser].followings removeObject:unfollowedUID];
                                                [[Authentication sharedInstance] synchronize];
                                                [self updateFollowOrNotButton];
                                                [self.tableView reloadData];
                                            } else {
                                                [SVProgressHUD dismissWithError:@"取消关注失败"];
                                            }
                                            [self.delegate userUnfollowed:_user];
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"取消关注失败"];
                                        }];
}

-(void)follow{
    int myID = [Authentication sharedInstance].currentUser.uID;
    
    NSArray *params = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", self.user.uID], @"value", @"user_id", @"key", nil]];
    http_method_t method = POST;
    NSString* url = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/following/", HTTPS, EOHOST, myID];
    [SVProgressHUD showWithStatus:@"请稍候……" maskType:SVProgressHUDMaskTypeBlack];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:method
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD dismissWithSuccess:@"关注成功！" afterDelay:1];
                                                NSString* followingUserID = [NSString stringWithFormat:@"%d",_user.uID];
                                                [[Authentication sharedInstance].currentUser.followings addObject:followingUserID];
                                                [[Authentication sharedInstance] synchronize];
                                                [self updateFollowOrNotButton];
                                                [self.tableView reloadData];
                                            } else {
                                                [SVProgressHUD dismissWithError:[obj objectForKey:@"info"]];
                                            }
                                            [_delegate userFollowed:_user];
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:BLAME_NETWORK_ERROR_MESSAGE];
                                        }];
}


-(IBAction)block:(id)sender{
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未实现" message:@"未实现功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [a show];
}

-(void)editMotto:(id)sender{
    CellTextEditorViewController* controller = [[CellTextEditorViewController alloc] initWithText:_user.motto placeHolder:@"请输入签名" style:CellTextEditorStyleTextView];
    controller.delegate = self;
    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalView:)];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentModalViewController:nav animated:YES];
}

-(void)dismissModalView:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)editAvatar:(id)sender{
    _operation = ChangeAvatar;
    [self presentImagePicker];
}


-(void)addPhoto:(id)sender{
    _operation = AddPhoto;
    [self presentImagePicker];
}

-(void)presentImagePicker{
    if (!_imagePickerActions) {
        _imagePickerActions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"相册", nil];
    }
    [_imagePickerActions showFromToolbar:self.navigationController.toolbar];
}

-(BOOL)isViewForMyself{
    if (!_user) {
        return NO;
    }
    return [[Authentication sharedInstance].currentUser isEqual:_user];
}
-(void) requestNextMeal{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/user/%d/order/?format=json&order_by=meal__start_date", EOHOST, _user.uID] method:GET cachePolicy:TTURLRequestCachePolicyNetwork
                                        success:^(id obj) {
                                            NSArray *orders = [obj objectForKeyInObjects];
                                            if (orders && [orders count] > 0) {
                                                OrderInfo *order = [OrderInfo orderInfoWithData:[orders objectAtIndex:0]];
                                                _nextMealLabel.text = order.meal.topic;
                                                _nextMealTimeLabel.text = [DateUtil shortStringFromDate:order.meal.time];
                                            } else {
                                                _nextMealLabel.text = @"最近没有饭局";
                                                _nextMealTimeLabel.text = @"";
                                            }
                                        } failure:^{
                                            _nextMealLabel.text = @"获取饭局失败";
                                            _nextMealTimeLabel.text = @"";
                                        }];
}

-(void)loadComments{
    _loadingComments = YES;	
    NSString *requestStr = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/comments/?format=json", EOHOST, _user.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:GET
                                    cachePolicy:TTURLRequestCachePolicyNone 
                                        success:^(id obj) {  
                                            _commentItems = [NSMutableArray array];
                                            NSArray *comments = [obj objectForKeyInObjects];
                                            for (NSDictionary *comment in comments) {
                                                UserProfile *from_person = [UserProfile profileWithData:[comment objectForKey:@"from_person"]];
                                                NSString* user_comment = [comment objectForKey:@"message"];
                                                CommentTableItem *item = [CommentTableItem itemFromUser:from_person withComment:user_comment];
                                                [_commentItems addObject:item];
                                            }
                                            _loadingComments = NO;
                                            [self.tableView reloadData];
                                            [self.tableView setNeedsDisplay];
                                        } failure:^{
                                            NSLog(@"failed to fetch comments");
                                            [self.tableView setNeedsDisplay];
                                            _loadingComments = NO;
                                        }];
}

#pragma mark - Table view data source
-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
            if ([self isViewForMyself]) {
                return 330;
            } else {
                return 380;
            }
        case 1:
            return 40;
        case 2:
            return [self rowsForPhotoCell] == 1 ? 95 : 95 + 85;
        case 3:
            return indexPath.row == 1 ? 75 : 50;
        case 4:
            return 58;
        case 5:
            if (_commentItems && _commentItems.count > 0) {
                return [CommentTableItemCell tableView:self.tableView rowHeightForObject:[_commentItems objectAtIndex:indexPath.row]];
            } else {
                return 20;
            }
        default:
            return 0;
    }
}

-(NSInteger)rowsForPhotoCell{
    if (_photoCell) {
        return [_photoCell numberOfRows];
    }
    int photoCount = _user.photos.count + 1 + ([self isViewForMyself] ? 1 : 0);
    if (photoCount > 8) {
        return 2; //maximal 2 rows
    }
    if (photoCount % 4 == 0) {
        return photoCount / 4;
    } else {
        return photoCount / 4 + 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 5) {
        if (!_loadingComments && _commentItems.count > 0) {
            return _commentItems.count;
        }
    } else if (section == 3){
//        int count = 0;
//        if (_user.occupation && _user.occupation.length > 0) {
//            count++;
//        }
//        if (_user.college && _user.college.length > 0) {
//            count ++;
//        }
//        return count;
        return 3;
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *title = [_sections objectAtIndex:section];
    if (section == 1) {
        return [NSString stringWithFormat:title, _user.tags.count];
    }
    return title;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"UserDetailsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"UserDetailsCell" owner:self options:nil];//load the cell now
            cell = _userDetailsCell;
            _userDetailsCell = nil;
            _nextMealLabel.text = @"";
            _nextMealTimeLabel.text = @"";
            _photoView.initialImage = [UIImage imageNamed:@"anno.png"];
        }
        if ([self isViewForMyself]) {
            self.nextMealFrame.hidden = YES;
            self.restFrame.frame = CGRectMake(self.restFrame.frame.origin.x, 15, self.restFrame.frame.size.width, self.restFrame.frame.size.height);
        } else if (_user){
            [self requestNextMeal];
        }
        [_photoView setPathToNetworkImage:_user.avatarFullUrl forDisplaySize:_photoView.frame.size];
        _mottoLabel.text = _user.motto && _user.motto.length > 0 ? _user.motto : @"未设置签名";
        _age.text = _user.age ? [NSString stringWithFormat:@"%d岁", _user.age] : @"20岁";
        _gender.image = _user.genderImage;
        _constellation.text = _user.constellation;
        NSString* updated = @"未知时间";
        if ([self isViewForMyself]) {
            updated = @"0分钟前";
        } else if (_user.locationUpdatedTime) {
            NSTimeInterval interval = [_user.locationUpdatedTime timeIntervalSinceNow] > 0 ? 0 : -[_user.locationUpdatedTime timeIntervalSinceNow];
            updated = [DateUtil humanReadableIntervals: interval];
        }
        
        NSString* distance = [self isViewForMyself] ? @"0.00公里" : [DistanceUtil distanceToMe:_user];
        NSString *distanceAndUpdatedAt = [NSString stringWithFormat:@"%@ | %@", distance, updated];
        _distanceAndUpdatedAt.text = distanceAndUpdatedAt;
        
    } else if (indexPath.section == 1){
        static NSString* CellIdentifier = @"UserTagsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UserTagsCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        } 
        UserTagsCell* tagCell = (UserTagsCell* )cell;
        tagCell.tags = _user.tags;

    } else if(indexPath.section == 2){
        static NSString* CellIdentifier = @"PhotoThumbnailCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            BOOL editable = [self isViewForMyself];
            cell = [[PhotoThumbnailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier withUser:_user editable:editable];
            _photoCell = (PhotoThumbnailCell*)cell;
            ((PhotoThumbnailCell*)cell).delegate = self;
        }
    } else if(indexPath.section == 3){
        static NSString* CellIdentifier = @"UserInfoCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.detailTextLabel.textColor = [UIColor blueColor];
        }
        if (indexPath.row == 0) {
            cell.textLabel.text = @"学校";
            cell.detailTextLabel.text = _user.college;
        } else if (indexPath.row == 1){
            cell.textLabel.text = @"职业";
            cell.detailTextLabel.numberOfLines = 2;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", _user.industry, _user.occupation];
        } else if (indexPath.row == 2){
            cell.textLabel.text  = @"公司";
            cell.detailTextLabel.text = _user.workFor;
        }
    } else if(indexPath.section == 4) {
        static NSString* CellIdentifier = @"SocialCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.imageView.image = [UIImage imageNamed:@"weibo_short_48"];
            UIGestureRecognizer *tapGuesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(weiboIconTapped:)];
            tapGuesture.delegate  = self;
            cell.imageView.userInteractionEnabled = YES;
            [cell.imageView addGestureRecognizer:tapGuesture];
        }
       
    } else if(indexPath.section == 5){
        if (_loadingComments) {
            static NSString* CellIdentifier = @"LoadingCommentsCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                cell.textLabel.text = @"评论加载中……";
                cell.textLabel.font = [UIFont systemFontOfSize:12];
            }
        } else if(_commentItems.count == 0){
            static NSString* CellIdentifier = @"NoCommentsCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                cell.textLabel.text = @"暂时没有评论";
                cell.textLabel.font = [UIFont systemFontOfSize:12];
            }
        } else{
            static NSString* CellIdentifier = @"CommentsCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[CommentTableItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

            }
            CommentTableItem* comentItem = [_commentItems objectAtIndex:indexPath.row];
            CommentTableItemCell* commentCell = (CommentTableItemCell* )cell;
            [commentCell setObject:comentItem];
        }
        
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark PhotoThumbnailCellDelegate
-(void)didSelectAddPhoto{
    [self addPhoto:nil];
}

-(void) didSelectAvatar:(UIImage*)avatarImage withAllPhotos:(NSArray*)allPhotos atIndex:(NSInteger)index{
    [self showUsrPhotos:allPhotos atIndex:index];
}

-(void) showUsrPhotos:(NSArray*)photos atIndex:(NSInteger)index{
    PhotoViewController *pvc = [[PhotoViewController alloc] initWithPhotos:photos atIndex:index withBigPhotoUrls:[_user avatarAndPhotosFullUrls]]; //TODO test adding photos
    pvc.title = @"照片";
//    pvc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissTagViewController:)];
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tagC];
//    [self presentModalViewController:navigationController animated:YES];
    
    [self.navigationController pushViewController:pvc animated:YES];
}
-(void) didSelectUserPhoto:(UserPhoto*)userPhoto withAllPhotos:(NSArray*)allPhotos atIndex:(NSInteger)index{
    if ([self isViewForMyself]) {
        if (!_imageDeleteOrViewActions) {
            _imageDeleteOrViewActions = [[UIActionSheet alloc] initWithTitle:@"选择一个操作" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"查看", nil];
        }
        _selectedPhoto = userPhoto;
        _selectedIndex = index;
        _allPhotos = allPhotos;
        [_imageDeleteOrViewActions showFromToolbar:self.navigationController.toolbar];
    } else {
        [self showUsrPhotos:allPhotos atIndex:index];
    }
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    CGRect cropRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
    
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    cropRect = [originalImage convertCropRect:cropRect];
    UIImage *croppedImage = [originalImage croppedImage:cropRect];
    CGFloat length = croppedImage.size.height > croppedImage.size.width ? croppedImage.size.height : croppedImage.size.width;
    CGSize resizeSize = length > 640 ? CGSizeMake(640, 640) : croppedImage.size;
    UIImage *resizedImage = [croppedImage resizedImage:resizeSize imageOrientation:originalImage.imageOrientation];
    NSLog(@"crop and resizing - cropRect:%@ ==> %@ -> %@ -> %@",
          NSStringFromCGRect(cropRect),
          NSStringFromCGSize(originalImage.size),
          NSStringFromCGSize(croppedImage.size),
          NSStringFromCGSize(resizedImage.size) );
    _hud = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
	_hud.mode = MBProgressHUDModeAnnularDeterminate;
    if (_operation == ChangeAvatar) {
        [self doChangeAvatar:resizedImage];
    } else {
        [self doAddPhoto:resizedImage];
    }
}

-(void)doAddPhoto:(UIImage*) resizedImage{
    [[NetworkHandler getHandler] uploadImage:resizedImage toURL:[NSString stringWithFormat:@"user/%d/photos/", _user.uID] success:^(id obj){
        NSDictionary* result = obj;
        if ([[result objectForKey:@"status"] isEqualToString:@"OK"]) {
            UserPhoto* photo = [UserPhoto photoWithData:result];
            [_user.photos addObject:photo];
            [_photoCell addUploadedPhoto:photo withLocalImage:resizedImage];
            [[Authentication sharedInstance] relogin]; // to refresh photos, or we can just add the new photo TODO
            [self.tableView reloadData];
        }
        else {
            _hud.labelText = @"上传失败";
        }
        [_hud hide:YES];
        [self dismissModalViewControllerAnimated:YES];
    } failure:^{
        _hud.labelText = @"上传失败";
        [_hud hide:YES afterDelay:1];
        [self dismissModalViewControllerAnimated:YES];
        NSLog(@"failed to upload images");
        [self dismissModalViewControllerAnimated:YES];
    } progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
        _hud.progress = totalBytesLoaded * 1.0 / totalBytesExpected;
    }];
}

-(void)doChangeAvatar:(UIImage*) resizedImage{
    [[NetworkHandler getHandler] uploadImage:resizedImage toURL:[NSString stringWithFormat:@"user/%d/avatar/", _user.uID]
                                     success:^(id obj) {
                                         NSLog(@"avatar updated");
                                         _user.avatarURL  = [obj objectForKey:@"avatar"];
                                         self.photoView.initialImage = resizedImage;
                                         [self.photoView setPathToNetworkImage: [_user avatarFullUrl]];
                                         [self.tableView reloadData];
                                         [_photoCell changeAvatar:[_user avatarFullUrl] withLocalImage:resizedImage];
                                         [[Authentication sharedInstance] relogin];
                                         [_hud hide:YES];
                                         [self dismissModalViewControllerAnimated:YES];
                                     } failure:^{
                                         NSLog(@"failed to update avatar");
                                         _hud.labelText = @"上传失败";
                                         [_hud hide:YES afterDelay:1];
                                         [self dismissModalViewControllerAnimated:YES];
                                     }progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
                                         _hud.progress = totalBytesLoaded * 1.0 / totalBytesExpected;
                                     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){
        [self showAllTags];
    }
}
#pragma mark UserDetailSaveDelegate
-(void)userProfileUpdated:(UserProfile *)newProfile{
    _user = newProfile;
    [self.tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark CellTextEditorDelegate
-(void)valueSaved:(NSString *)value{
    _user.motto = value;
    [self.tableView reloadData];
    [self dismissModalViewControllerAnimated:YES];
    NSDictionary* paramDict = @{@"motto": value};
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%d/", HTTPS, EOHOST, _user.uID];
    [[NetworkHandler getHandler] sendJSonRequest:requestStr
                                          method:PATCH
                                      jsonObject:paramDict
                                         success:^(id obj) {
                                             NSLog(@"motto updated");
                                         } failure:^{
                                             NSLog(@"failed to update motto to %@", value);
                                             [SVProgressHUD dismissWithError:@"更新签名失败"];
                                         }];
}



#pragma mark TTPostControllerDelegate
- (BOOL)postController:(TTPostController*)postController willPostText:(NSString*)text {
    BOOL messageOrComment = [postController.title isEqualToString:TAG_MSG];//YES=message, NO=comment
    NSArray *params = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys: messageOrComment ? @"0" : @"1", @"value", @"type", @"key", nil],
                       [NSDictionary dictionaryWithObjectsAndKeys:text, @"value", @"message", @"key", nil], nil];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/messages/", HTTPS, EOHOST, self.user.uID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"]) {
                                                [SVProgressHUD dismissWithSuccess:@"发送成功"];
                                                if (messageOrComment) {
                                                    NSLog(@"message sent");
                                                } else {
                                                    [SVProgressHUD showSuccessWithStatus:[obj objectForKey:@"info"]];
                                                    [_commentItems addObject:[CommentTableItem itemFromUser:[Authentication sharedInstance].currentUser withComment:text]];
                                                    [self.tableView reloadData];
                                                }
                                            } else {
                                                [SVProgressHUD dismissWithError:@"发送失败"];
                                            }
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"发送失败"];
                                        }];
    
    return YES;
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
                [self showUsrPhotos:_allPhotos atIndex:_selectedIndex];
                break;
            default:
                break;
        }
    } else if(_imagePickerActions == actionSheet){
        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if (buttonIndex == 0) {
            pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else if (buttonIndex == 2){
            return;
        }
        pickerController.delegate = self;
        pickerController.allowsEditing = YES;
        [self presentModalViewController:pickerController animated:YES];
    }
}

-(void)deleteUserPhoto:(UserPhoto*)photo{
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/userphoto/%d/", EOHOST, photo.pID]
                                         method:DELETE
                                     parameters:@[]
                                    cachePolicy:TTURLRequestCachePolicyNoCache
                                        success:^(id obj) {
                                            [SVProgressHUD dismissWithSuccess:@"删除成功"];
                                            [_user.photos removeObject:photo];
                                            [_photoCell deleteUserPhoto:photo atIndex:_selectedIndex];
                                            [self.tableView reloadData];
                                            NSLog(@"user photo %d delete.", photo.pID);
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"删除失败"];
                                        }]; 
}

-(void)showAllTags{
    UserTagsViewController* utvc = [[UserTagsViewController alloc] initWithUser:_user];
    utvc.tagDelegate = self;
    [self.navigationController pushViewController:utvc animated:YES];
}

#pragma mark -
#pragma mark PullRefreshTableViewController
- (void)pullToRefresh {
    [self reload:NO];
}

-(void)reload:(BOOL)useCache{
    TTURLRequestCachePolicy policy = useCache ? TTURLRequestCachePolicyDefault : TTURLRequestCachePolicyNone;
    NSString* url = [NSString stringWithFormat:@"http://%@/api/v1/user/%d/?format=json", EOHOST, _user.uID];
    [[NetworkHandler getHandler] requestFromURL:url
                                         method:GET
                                    cachePolicy:policy
                                        success:^(id obj) {
                                            UserProfile *user = [UserProfile profileWithData:obj];
                                            [self setUser:user];
                                            _photoCell.user = user;
                                            [self stopLoading];
                                        } failure:^{
                                            [SVProgressHUD dismissWithError:@"更新数据失败"];
                                            [self stopLoading];
                                        }];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)weiboIconTapped:(id)sender{
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
    [self.tableView reloadData];
}
@end
