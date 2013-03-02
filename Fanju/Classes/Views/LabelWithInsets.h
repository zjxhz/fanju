//
//  LabelWithInsets.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

//Labels with 5 insets on left
@interface LabelWithInsets : UILabel{
    
}
- (id)initWithFrame:(CGRect)frame leftInset:(int)leftInset rightInset:(int)rightInset;

@property int leftInset;
@property int rightInset;
@end
