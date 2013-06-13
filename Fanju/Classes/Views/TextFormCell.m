//
//  TextFormCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextFormCell.h"

@implementation TextFormCell

@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Adding the text field
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.clearsOnBeginEditing = NO;
        textField.textAlignment = UITextAlignmentRight;
        textField.returnKeyType = UIReturnKeyDone;
        [self.contentView addSubview:textField];
    }
    return self;
}


#pragma mark -
#pragma mark Laying out subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = CGRectMake(MarginBetweenControls, 
                             12.0, 
                             self.contentView.bounds.size.width - 9.0 - MarginBetweenControls,
                             25.0);
    [textField setFrame:rect];
}

@end
