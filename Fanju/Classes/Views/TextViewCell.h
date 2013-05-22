//
//  TextViewCell.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

//a subtitle style cell with multiple line text view
@interface TextViewCell : UITableViewCell
@property(nonatomic, strong) UITextView* textView;
@property(nonatomic, readonly) CGFloat preferredHeight;
@end
