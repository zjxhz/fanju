//
//  ImageScrollView.h
//  ImagePdfViewer
//
//  Created by 浣泽 徐 on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface ImageScrollView : UIScrollView <UIScrollViewDelegate>
@property(nonatomic, readonly) NINetworkImageView* imageView;
- (void) zoomReset;

@end
