//
//  AlbumViewController.m
//  Fanju
//
//  Created by Xu Huanze on 4/18/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "AlbumViewController.h"
#import "NINetworkImageView.h"
#import "PhotoViewController.h"
#import "WidgetFactory.h"
#import "Authentication.h"
#import "SVProgressHUD.h"
#import "DictHelper.h"
#import "UserService.h"
#import "Photo.h"
#import "RestKit.h"
#import "URLService.h"

#define PHOTO_BG_WIDTH 105
#define PHOTO_BG_HEIGHT PHOTO_BG_WIDTH
#define PHOTO_WIDTH 95
#define PHOTO_HEIGHT PHOTO_WIDTH
#define PHOTO_BG_GAP 1
#define TABBAR_HEIGHT 49
@interface AlbumViewController (){
    UIScrollView* _scrollView;
    NSMutableArray* _photoViews;
    NSMutableArray* _contentViews;
    BOOL _editing;
    NSMutableSet* _selectedIndexes;
    UIView* _tabBar;
    UIButton* _deleteButton;
    ImageUploader* _uploader;
    UIButton* _addButton;
    NSArray* _photos;
    NSManagedObjectContext* _mainQueueContext;
    BOOL _tabBarVisible;
    BOOL _addButtonVisible;
}

@end

@implementation AlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
        _mainQueueContext = store.mainQueueManagedObjectContext;
        self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"相册"];
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:_scrollView];
        UITapGestureRecognizer *tp = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [_scrollView addGestureRecognizer:tp];
        _addButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_addButton setBackgroundImage:[UIImage imageNamed:@"album_add_photo"] forState:UIControlStateNormal];
        [_addButton addTarget:self action:@selector(addPhoto:) forControlEvents:UIControlEventTouchUpInside];

    }
    return self;
}

-(void)setUser:(User *)user{
    _user = user;
    if ([[UserService service].loggedInUser isEqual:_user]) {
        self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory]normalBarButtonItemWithTitle:@"编辑" target:self action:@selector(edit:)];
    }
    [self buildUI];
}

-(void)edit:(id)sender{
    _editing = !_editing;
    UIBarButtonItem* rightItem = self.navigationItem.rightBarButtonItem;
    UIButton* rightButton = (UIButton*)rightItem.customView;
    NSString* title = nil;
    if (_editing) {
         title = @"取消";
        _selectedIndexes = [NSMutableSet set];
        [self addTabBar];
    } else {
        title = @"编辑";
        [self removeTabBar];
        for (UIView* view in _contentViews) {
            [self removeDeleteMarkInView:view];
        }
    }
    [rightButton setTitle:title forState:UIControlStateNormal];
    [self addAddButtonIfNeeded];
    [self resetContentSize];
}

-(void)removeTabBar{
    [UIView animateWithDuration:0.5
                     animations:^{
        CGRect frame = _tabBar.frame;
        frame.origin.y += frame.size.height;
        _tabBar.frame = frame;
        CGPoint offset = _scrollView.contentOffset;
        CGFloat y = offset.y - TABBAR_HEIGHT;
        if (y < 0) {
            y = 0;
        }
        _scrollView.contentOffset = CGPointMake(offset.x, y);
    } completion:^(BOOL finished) {
        _tabBarVisible = NO;
        [self resetScrollViewFrame];
        [_tabBar removeFromSuperview];
    }];
}

-(void)addTabBar{
    UIImage* deleteImg = [UIImage imageNamed:@"album_delete_photo"];
    _deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, deleteImg.size.width, deleteImg.size.height)];
    [_deleteButton setBackgroundImage:deleteImg forState:UIControlStateNormal];
    [_deleteButton setTitle:@"删除" forState:UIControlStateNormal];
    [self updateDeleteButton];
    _tabBar = [[WidgetFactory sharedFactory] tabBarInView:self.view withButton:_deleteButton];

    [self.view addSubview:_tabBar];
    __block CGRect frame = _tabBar.frame;
    frame.origin.y += frame.size.height;
    _tabBar.frame = frame;
    [UIView animateWithDuration:0.5 animations:^{
        frame.origin.y -= frame.size.height;
        _tabBar.frame = frame;
        CGPoint offset = _scrollView.contentOffset;
        _scrollView.contentOffset = CGPointMake(offset.x, offset.y + TABBAR_HEIGHT);
    } completion:^(BOOL finished) {
        _tabBarVisible = YES;
        [self resetScrollViewFrame];
    }];
}

-(void)deletePhotos:(id)sender{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    NSMutableString* photoIDsStr = [[NSMutableString alloc] init];
    NSMutableArray* photosToBeDeleted = [NSMutableArray array];
    for (NSNumber* indexNumber in _selectedIndexes) {
        NSInteger index = [indexNumber integerValue];
        Photo* photo = _photos[index];
        [photosToBeDeleted addObject:photo];
        [photoIDsStr appendFormat:@"%@,", photo.pID];
    }
    NSArray* params = @[[DictHelper dictWithKey:@"deleted_ids" andValue:photoIDsStr]];
    [photoIDsStr deleteCharactersInRange:NSMakeRange(photoIDsStr.length - 1, 1)];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"http://%@/api/v1/userphoto/", EOHOST]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNoCache
                                        success:^(id obj) {
                                            [SVProgressHUD showSuccessWithStatus:@"删除成功"];
                                            [_user removePhotos:[[NSSet alloc] initWithArray:photosToBeDeleted]];
                                            for (Photo* photo in photosToBeDeleted) {
                                                [_mainQueueContext deleteObject:photo];
                                            }
                                            NSError* error;
                                            if(![_mainQueueContext saveToPersistentStore:&error]){
                                                DDLogError(@"failed to save deleted photos");
                                            }
                                            [_selectedIndexes removeAllObjects];
                                            [self buildUI];
                                            [self edit:nil];
                                            DDLogVerbose(@"user photos deleted.");
                                        } failure:^{
                                            [SVProgressHUD showErrorWithStatus:@"删除失败"];
                                        }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self resetScrollViewFrame];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//this method could be called multiple times
-(void)buildUI{
    [_contentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _photos = [UserService sortedPhotosForUser:_user];
    _photoViews = [NSMutableArray array];
    _contentViews = [NSMutableArray array];
    for (int i = 0; i < _photos.count; ++i) {
        [self addPhoto:[_photos objectAtIndex:i] atIndex:i];
    }
    [self addAddButtonIfNeeded];
    [self updateDeleteButton];
    [self resetContentSize];
}

-(void)resetContentSize{
    NSInteger tiles = _photos.count;
    if (_addButtonVisible) {
        tiles++;
    }
    NSInteger rows =  tiles/ 3 + (tiles % 3 == 0 ? 0 : 1);
    _scrollView.contentSize = CGSizeMake( self.view.frame.size.width, rows *  (PHOTO_BG_WIDTH + PHOTO_BG_GAP));
}

-(void)addAddButtonIfNeeded{
    if (_user.photos.count < 15 && [[UserService service].loggedInUser isEqual:_user] &&!_editing) {
        [_addButton removeFromSuperview];
        _addButton.frame = [self frameAtIndex:_user.photos.count];
        [_scrollView addSubview:_addButton];
        _addButtonVisible = YES;
    } else {
        [_addButton removeFromSuperview];
        _addButtonVisible = NO;
    }
}

-(void)addPhoto:(id)sender{
    if (!_uploader) {
        _uploader = [[ImageUploader alloc] initWithViewController:self delegate:self];
    }
    [_uploader uploadPhoto];
}
-(void)updateDeleteButton{
    if (_editing && _selectedIndexes.count > 0) {
        _deleteButton.enabled = YES;
        [_deleteButton addTarget:self action:@selector(deletePhotos:) forControlEvents:UIControlEventTouchUpInside];
        _deleteButton.alpha = 1.0;
    } else {
        _deleteButton.enabled = NO;
        [_deleteButton removeTarget:self action:@selector(deletePhotos:) forControlEvents:UIControlEventTouchUpInside];
        _deleteButton.alpha = 0.5;
    }
}

-(void)addPhoto:(Photo*)photo atIndex:(NSInteger)index{
    UIImage* photoBG = [UIImage imageNamed:@"album_photo_bg"];
    UIView* contentView = [[UIView alloc] initWithFrame:[self frameAtIndex:index]];
    UIImageView *bgView = [[UIImageView alloc] initWithImage:photoBG];
    [contentView addSubview:bgView];
    NINetworkImageView* photoView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(5, 5, PHOTO_WIDTH, PHOTO_HEIGHT)];
    photoView.contentMode = UIViewContentModeScaleAspectFill;
    [photoView setPathToNetworkImage:[URLService  absoluteURL:photo.thumbnailURL] forDisplaySize:CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT)];
    [contentView addSubview:photoView];
    [_scrollView addSubview:contentView];
    [_photoViews addObject:photoView];
    [_contentViews addObject:contentView];
    
}

-(CGRect)frameAtIndex:(NSInteger)index{
    return CGRectMake(PHOTO_BG_GAP + (PHOTO_BG_WIDTH + PHOTO_BG_GAP) * (index % 3), 4 + (PHOTO_BG_WIDTH + PHOTO_BG_GAP) * (index / 3), PHOTO_BG_WIDTH, PHOTO_BG_HEIGHT);
}

-(void)viewTapped:(UITapGestureRecognizer*)tap{
    CGPoint tapPoint = [tap locationInView:_scrollView];
    NSInteger row = tapPoint.y / (PHOTO_BG_WIDTH + PHOTO_BG_GAP);
    NSInteger column = tapPoint.x / (PHOTO_BG_WIDTH + PHOTO_BG_GAP);
    NSInteger index = row * 3 + column;
    if (_editing) {
        if (index < _user.photos.count){
            UIView* contentView = [_contentViews objectAtIndex:index];
            NSNumber* indexNumber = [NSNumber numberWithInt:index];
            if ([_selectedIndexes containsObject:indexNumber]) {
                [_selectedIndexes removeObject:indexNumber];
                [self removeDeleteMarkInView:contentView];
            } else {
                [_selectedIndexes addObject:indexNumber];
                UIImage* deleteImg = [UIImage imageNamed:@"album_delete_mark"];
                UIImageView* deleteView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, deleteImg.size.width, deleteImg.size.height)];
                deleteView.tag = 333; //for later removal
                deleteView.image = deleteImg;
                [contentView addSubview:deleteView];
            }
        }
        [self updateDeleteButton];
    } else{
        if (index < _user.photos.count) {
            PhotoViewController* vc = [[PhotoViewController alloc] initWithUser:_user atIndex:index];
            vc.title = [NSString stringWithFormat:@"%@的照片", _user.name];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)removeDeleteMarkInView:(UIView*)view{
    for (UIView* subview in view.subviews) {
        if (subview.tag == 333) {
            [subview removeFromSuperview];
        }
    }
}

-(NSArray*)allPhotos{
    NSMutableArray* photos = [NSMutableArray array];
    for (Photo* photo in _photos) {
        [photos addObject:[URLService absoluteURL:photo.thumbnailURL]];
    }
    return photos;
}

-(void)resetScrollViewFrame{
    CGRect frame = self.view.frame;
    if (_tabBarVisible) {
        frame.size.height -= TABBAR_HEIGHT;
    }
    _scrollView.frame = frame;
}
#pragma mark ImageUploaderDelegate
-(void)didUploadPhoto:(Photo*)photo image:(UIImage*)image{
    [_selectedIndexes removeAllObjects];
    [self buildUI];
}

-(void)didFailUploadPhoto:(UIImage*)image{
    DDLogError(@"failed to upload image");
}
@end
