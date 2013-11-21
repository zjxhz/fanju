//
//  MyCustomStylesheet.m
//  EasyOrder
//
//  Created by igneus on 12/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MyCustomStylesheet.h"
#import <Three20Style/UIColorAdditions.h>

@implementation MyCustomStylesheet

- (TTStyle*)launcherButton:(UIControlState)state {
    return
    [TTPartStyle styleWithName:@"image" style:TTSTYLESTATE(launcherButtonImage:, state) next:
     [TTTextStyle styleWithFont:[UIFont systemFontOfSize:15] color:RGBCOLOR(80, 80, 80)
                minimumFontSize:11 shadowColor:nil
                   shadowOffset:CGSizeZero next:nil]];
}

- (TTStyle*)launcherButtonImage:(UIControlState)state {
    TTStyle* style =
    [TTBoxStyle styleWithMargin:UIEdgeInsetsMake(0, 0, 0, 0) padding:UIEdgeInsetsMake(35, 35, 50, 35) next:
     [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
      [TTImageStyle styleWithImageURL:nil defaultImage:nil contentMode:UIViewContentModeScaleAspectFit
                                 size:CGSizeZero next:nil]]];

    if (state == UIControlStateHighlighted || state == UIControlStateSelected) {
        [style addStyle:
         [TTBlendStyle styleWithBlend:kCGBlendModeSourceAtop next:
          [TTSolidFillStyle styleWithColor:RGBACOLOR(0,0,0,0.3) next:nil]]];
    }
    
    return style;
}

- (TTStyle*)embossedBackButton:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return [TTShapeStyle styleWithShape:[TTRoundedLeftArrowShape shapeWithRadius:4.5] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 0, 0) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(248, 190, 0)
                                               color2:RGBCOLOR(216, 165, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 10, 12) next:
              [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, 0) next:nil]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedLeftArrowShape shapeWithRadius:4.5] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 0, 0) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(218, 160, 0)
                                               color2:RGBCOLOR(186, 135, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 10, 12) next:
              [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, 0) next:nil]]]]]];
    } else {
        return nil;
    }
}

- (TTStyle*)embossedButton:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
                [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 0, 0) next:
                 [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(248, 190, 0)
                                                     color2:RGBCOLOR(216, 165, 0) next:
                  [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
                   [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 10, 12) next:
                    [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                                   shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                                  shadowOffset:CGSizeMake(0, 0) next:nil]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 0, 0) next:
          [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(218, 160, 0)
                                              color2:RGBCOLOR(186, 135, 0) next:
           [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
            [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 10, 12) next:
             [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                            shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                           shadowOffset:CGSizeMake(0, 0) next:nil]]]]]];
    } else if (state == UIControlStateDisabled) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 0, 0) next:
          [TTLinearGradientFillStyle styleWithColor1:[UIColor lightGrayColor]
                                              color2:[UIColor lightGrayColor] next:
           [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
            [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 10, 12) next:
             [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                            shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                           shadowOffset:CGSizeMake(0, 0) next:nil]]]]]];
    }
    else {
        return nil;
    }
}

- (TTStyle*)tabGrid {
    return
    [TTBoxStyle styleWithMargin:UIEdgeInsetsMake(0, 0, 0, 0) padding:UIEdgeInsetsMake(0, 0, 0, 0) next:nil];
}

- (TTStyle*)tabGridTabImage:(UIControlState)state {
    return
    [TTBoxStyle styleWithMargin:UIEdgeInsetsMake(0, 0, 0, 0) padding:UIEdgeInsetsMake(7, 7, 5, 5) next:
     [TTImageStyle styleWithImageURL:nil defaultImage:nil contentMode:UIViewContentModeScaleAspectFit
                                size:CGSizeMake(20, 20) next:nil]];
}

- (UIColor*)toolbarButtonTextColorForState:(UIControlState)state {
    return [UIColor blackColor];
}

- (UIFont*)buttonFont {
    return [UIFont systemFontOfSize:12];
}

- (UIColor*)navigationBarTintColor{
    return [UIColor whiteColor];
}

@end
