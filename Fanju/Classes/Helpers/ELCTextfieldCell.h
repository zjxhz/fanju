//
//  ELCTextfieldCell.h
//  MobileWorkforce
//
//  Created by Collin Ruffenach on 10/22/10.
//  Copyright 2010 ELC Tech. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ELCTextfieldCell : UITableViewCell <UITextFieldDelegate> {

	id __unsafe_unretained delegate;
	UILabel *leftLabel;
	UITextField *rightTextField;
	NSIndexPath *indexPath;
    UIButton *button;
}

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UITextField *rightTextField;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIButton *button;

@end

@protocol ELCTextFieldDelegate

-(void)textFieldDidReturnWithIndexPath:(NSIndexPath*)_indexPath;
-(void)updateTextLabelAtIndexPath:(NSIndexPath*)_indexPath string:(NSString*)_string;
-(void)buttonClickedWithIndexPath:(NSIndexPath*)_indexPath;

@end