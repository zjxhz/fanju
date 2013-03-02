//
//  ImageScrollView.h
//  ImagePdfViewer
//
//  Created by 浣泽 徐 on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageScrollView : UIScrollView <UIScrollViewDelegate>
- (id) initWithFrame:(CGRect)frame image:(UIImage*)image contentMode:(UIViewContentMode)mode;
@property(nonatomic, readonly) UIImageView* imageView;
- (void) zoomReset;

@end
