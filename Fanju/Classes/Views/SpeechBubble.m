//
//  SpeechLabel.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SpeechBubble.h"
#define H_PADDING 5
#define V_PADDING 5
#define MAX_HEIGHT 100

@implementation SpeechBubble
//fixed height with one row label
- (id)initWithText:(NSString*)text
              font:(UIFont*)font
            origin:(CGPoint)origin
     pointLocation:(CGFloat)location
             width:(CGFloat)width
            height:(CGFloat)height{
    self = [super init];
    if (self) {
        int contentWidth = [self isPointLocationOnTop:location] ? width - 10 : width - 20;
        CGSize textSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(contentWidth, MAX_HEIGHT)];
        int calcHeight = height;
        if (calcHeight == 0) {
            calcHeight = [self isPointLocationOnTop:location] ? textSize.height + 20 : textSize.height + 10;
        }
        CGFloat angle = [self isPointLocationOnLeft:location] ? 0 : 180;
        
        TTStyle *textStyle = [TTTextStyle styleWithFont:[UIFont systemFontOfSize:12] color:[UIColor blackColor] textAlignment:UITextAlignmentLeft next:nil];
        UIColor* bgColor = [self isPointLocationOnLeft:location] ? [UIColor greenColor] : [UIColor whiteColor];
        TTStyle *style =
        [TTShapeStyle styleWithShape:[TTSpeechBubbleShape shapeWithRadius:5
                                                            pointLocation:location
                                                               pointAngle:angle
                                                                pointSize:CGSizeMake(10,10)]
                                next:[TTSolidFillStyle styleWithColor:bgColor
                                                                 next:[TTSolidBorderStyle styleWithColor:RGBCOLOR(0xC2, 0xC2, 0xC2)
                                                                                                   width:1
                                                                                                    next:textStyle]]];
        self.style = style;
        CGFloat bubbleWidth = textSize.width + 30 < width ? textSize.width  + 30 : width;
        if ([self isPointLocationOnRight:location] && bubbleWidth < width) {
            origin.x = origin.x + width - bubbleWidth;
        }
        self.frame = CGRectMake(origin.x, origin.y, bubbleWidth, calcHeight);
        self.backgroundColor = [UIColor whiteColor];
        
        int x = [self isPointLocationOnLeft:location] ? H_PADDING + 15 : H_PADDING ;
        int y = [self isPointLocationOnTop:location] ? V_PADDING + 10 : V_PADDING;
        CGFloat textHeight = [self isPointLocationOnTop:location] ? calcHeight - 20 :  calcHeight - 10 ;
        UILabel *speechLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, textSize.width, textHeight)];
        if (height == 0) {
            speechLabel.numberOfLines = 0;
            speechLabel.lineBreakMode = UILineBreakModeWordWrap;
        } else {
            speechLabel.numberOfLines = 1;
        }
        speechLabel.text = text;
        speechLabel.font = font;
        speechLabel.backgroundColor = [UIColor clearColor];
        speechLabel.textColor = [UIColor blackColor];
        [self addSubview:speechLabel];
    }
    
    return self;
}

//flexible height
- (id)initWithText:(NSString*)text
              font:(UIFont*)font
            origin:(CGPoint)origin
     pointLocation:(CGFloat)location
             width:(CGFloat)width{
    return [self initWithText:text font:font origin:origin pointLocation:location width:width height:0];
}

-(BOOL)isPointLocationOnTop:(CGFloat)location{
    return location >=45 && location < 135;
}

-(BOOL)isPointLocationOnLeft:(CGFloat)location{
    return location < 45 ;
}

-(BOOL)isPointLocationOnRight:(CGFloat)location{
    return location > 135 ;
}
@end
