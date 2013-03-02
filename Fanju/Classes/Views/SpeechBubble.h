//
//  SpeechLabel.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"

@interface SpeechBubble : TTView

- (id)initWithText:(NSString*)text font:(UIFont*)font origin:(CGPoint)origin pointLocation:(CGFloat)location width:(CGFloat)width;

- (id)initWithText:(NSString*)text
              font:(UIFont*)font
            origin:(CGPoint)origin
     pointLocation:(CGFloat)location
             width:(CGFloat)width
            height:(CGFloat)height;

@end
