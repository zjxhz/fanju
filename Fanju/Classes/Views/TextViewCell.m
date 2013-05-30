//
//  TextViewCell.m
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TextViewCell.h"

@implementation TextViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.backgroundColor = [UIColor clearColor];
        self.contentView.clipsToBounds = YES;
        [self.contentView addSubview:_textView];
        self.detailTextLabel.text = @"  ";// hack to move the textLabel up
        
        UIToolbar * topView = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
        UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyBoard)];
        [topView setItems:@[btnSpace, doneButton]];
        [_textView setInputAccessoryView:topView];
    }
    return self;
}

-(IBAction)dismissKeyBoard{
    [_textView resignFirstResponder];
}


#pragma mark -
#pragma mark Laying out subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.origin.y = 10;
    self.textLabel.frame = textLabelFrame;
    
    CGFloat y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 5;
//    CGSize textSize = [_textView.text sizeWithFont:[UIFont systemFontOfSize:15.0f] constrainedToSize:CGSizeMake(self.contentView.bounds.size.width, 400) lineBreakMode: UILineBreakModeWordWrap];
//    CGFloat height = textSize.height;
    CGFloat height = 50;
    CGRect rect = CGRectMake(0, y, self.contentView.bounds.size.width, height);
    _textView.frame = rect;
//    [_textView sizeToFit];
    _preferredHeight = _textView.frame.origin.y + _textView.frame.size.height + 10;
}


@end
