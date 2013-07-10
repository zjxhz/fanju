//
//  ImageScrollView.m
//  ImagePdfViewer
//
//  Created by 浣泽 徐 on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageScrollView.h"

@implementation ImageScrollView
- (id) initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        _imageView = [[NINetworkImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_imageView];
        self.maximumZoomScale = 2.0;
        self.minimumZoomScale = 1.0;
        [self zoomReset];
    }
    return self;
}

-(id)init{
    return [self initWithFrame:CGRectZero];
}



-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
}

-(void) zoomReset{
    self.zoomScale = 1.0;
}
@end
