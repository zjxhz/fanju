//
//  PhotoViewController.m
//  Jade3
//
//  Created by 浣泽 徐 on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoViewController.h"
#import "SimplePhotoSet.h"
#import "ImageScrollView.h"
#import "MBProgressHUD.h"

#define SCROLL_VIEW_CONENT_WIDTH 320

@interface PhotoViewController (){
//    UIView* _zoomViewForScrollView;
    NSMutableArray* _contentViews;
    NSMutableArray* _imageViews;
    UIScrollView* _scrollView;
    NSArray* _bigPhotoUrls;
    BOOL _fullScreen;
    MBProgressHUD* _hud;
    NSMutableSet* _loadedURLs;
    NSTimer* _progressTimer;
}

@end

@implementation PhotoViewController
@synthesize photoSource = _photoSource;
-(id) initWithPhotos:(NSArray*)photos atIndex:(NSInteger)index withBigPhotoUrls:(NSArray*)bigPhotoUrls{
    if (self = [super init]) {
        _photoSource = [[SimplePhotoSet alloc] initWithPhotos:photos];
        _initialIndex = index;
        _contentViews = [NSMutableArray array];
        _imageViews = [NSMutableArray array];
        _bigPhotoUrls = bigPhotoUrls;
        _loadedURLs = [NSMutableSet set];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.wantsFullScreenLayout = YES;
    [self viewInFullScreen:YES];
    _fullScreen = YES;
    CGFloat height = [[UIScreen mainScreen] applicationFrame].size.height;
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self.view addGestureRecognizer:tap];
    _scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_scrollView.autoresizesSubviews = YES;
    [_scrollView setMaximumZoomScale:2.0];
    [_scrollView setMinimumZoomScale:0.5];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    [_scrollView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    
    for(int i=0; i < _photoSource.numberOfPhotos; i++){
        CGFloat xOrigin = i * 320;
        //check if big photo is available from cache
        NSString* currentURL = [_bigPhotoUrls objectAtIndex:i];
        NSData* data =  [[TTURLCache sharedCache] dataForURL:currentURL];
        UIImage* image = [UIImage imageWithData:data];
        
        CGRect imageFrame = CGRectZero;
        UIViewContentMode mode = UIViewContentModeScaleAspectFit;
        if (image) {
            [_loadedURLs addObject:currentURL];
            imageFrame = [[UIScreen mainScreen] applicationFrame];
            CGFloat radio = image.size.height / image.size.width;
            if (radio > 1.3 && radio < 2) {
                mode = UIViewContentModeScaleAspectFill;
            }
        } else {
            image = [_photoSource photoAtIndex:i];
            CGFloat imageX = (SCROLL_VIEW_CONENT_WIDTH - image.size.width) / 2;
            CGFloat imageY = (SCROLL_VIEW_CONENT_WIDTH - image.size.height) / 2;
            imageFrame = CGRectMake(imageX, imageY, image.size.width, image.size.height);
        }
        ImageScrollView* imageScrollView = [[ImageScrollView alloc] initWithFrame:CGRectMake(xOrigin, 0, SCROLL_VIEW_CONENT_WIDTH, height) image:image contentMode:mode];
        imageScrollView.backgroundColor = [UIColor blackColor];
        imageScrollView.imageView.frame = imageFrame;
        
        [_imageViews addObject:imageScrollView.imageView];
        [_scrollView addSubview:imageScrollView];
    }
    
    _scrollView.contentSize = CGSizeMake(_photoSource.numberOfPhotos * SCROLL_VIEW_CONENT_WIDTH, height);
    _scrollView.contentOffset = CGPointMake(_initialIndex * SCROLL_VIEW_CONENT_WIDTH, 0 );
    [self.view addSubview:_scrollView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [self.navigationController.view setNeedsLayout];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self requestImageForCurrentPage];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.wantsFullScreenLayout = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController.view setNeedsLayout];
}

-(void)requestImageForCurrentPage{
    int index = _scrollView.contentOffset.x / SCROLL_VIEW_CONENT_WIDTH;
    NSString* currentURL = [_bigPhotoUrls objectAtIndex:index];
    if ([_loadedURLs containsObject:currentURL]) {
        return;
    }
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
	_hud.mode = MBProgressHUDModeAnnularDeterminate;
    TTURLRequest* request = [TTURLRequest requestWithURL:currentURL delegate:self];
    request.response = [[TTURLImageResponse alloc] init];
    [_progressTimer invalidate];
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgress:) userInfo:request repeats:YES];
    [request send];

}
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{    
    [self requestImageForCurrentPage];
}

-(BOOL)isURLForCurrentPage:(NSString*)url{
    int index = _scrollView.contentOffset.x / SCROLL_VIEW_CONENT_WIDTH;
    NSString* urlOfCurrentPage = [_bigPhotoUrls objectAtIndex:index];
    return [url isEqualToString:urlOfCurrentPage];
}

#pragma mark TTURLRequestDelegate
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    if([self isURLForCurrentPage:request.urlPath])
    {
        int index = _scrollView.contentOffset.x / SCROLL_VIEW_CONENT_WIDTH;
        [_hud hide:YES];
        TTURLImageResponse* response = request.response;
        [UIView animateWithDuration:0.6 animations:^{
            [self setBigPhoto:response.image atIndex:index];
        }];
        [_progressTimer invalidate];
    }
    [_loadedURLs addObject:request.urlPath];
    
}

- (void)setBigPhoto:(UIImage*)image  atIndex:(int)index {
    UIImageView* imageView = [_imageViews objectAtIndex:index];
    imageView.frame = [[UIScreen mainScreen] applicationFrame];
    CGFloat radio = image.size.height / image.size.width;
    if (radio > 1.3 && radio < 2) {
        imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    imageView.image = image;
}


- (void)updateProgress:(NSTimer*)timer{
    TTURLRequest* request = timer.userInfo;
    if([self isURLForCurrentPage:request.urlPath]){
        _hud.progress = request.totalBytesDownloaded * 1.0 / request.totalContentLength;
    }
    DDLogVerbose(@"downloading %d/%d: %.2f%% from: %@", request.totalBytesDownloaded, request.totalContentLength, request.totalBytesDownloaded * 100.0 / request.totalContentLength, request.urlPath);
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error{
    _hud.labelText = @"下载失败，请稍后再试";
    [_hud hide:YES afterDelay:2];
    DDLogError(@"failed to load image from %@", request.urlPath);
}

-(void)viewTapped:(id)sender{
    _fullScreen = !_fullScreen;
    [self viewInFullScreen:_fullScreen];
}

-(void)viewInFullScreen:(BOOL)fullScreen{
    [[UIApplication sharedApplication] setStatusBarHidden:fullScreen];
    [self.navigationController setNavigationBarHidden:fullScreen];
}
@end
