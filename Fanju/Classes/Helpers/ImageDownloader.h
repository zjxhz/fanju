//
//  ImageDownloader.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/27/12.
//
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"
#import "MealInfo.h"
#import "UserProfile.h"

@protocol ImageDownloaderDelegate
- (void)imageDidLoad:(NSIndexPath *)indexPath;
- (void)mealImageDidLoad:(NSIndexPath*) indexPath withImage:(UIImage*)image;
- (void)userSmallAvatarDidLoad:(NSIndexPath*) indexPath withImage:(UIImage*)image forUser:(UserProfile*)user;
- (void)didFinishLoad:(NSIndexPath*)indexPath;
@end

@interface ImageDownloader : NSObject <TTURLRequestDelegate>{
    NSInteger _finishedCounts;
}

@property(nonatomic, weak) id<ImageDownloaderDelegate> delegate;
@property(nonatomic, strong) UIImage* image;
@property (nonatomic, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, weak) MealInfo* meal;
-(void)startDownload;

@end
