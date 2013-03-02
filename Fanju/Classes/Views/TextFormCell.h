//
//  TextFormCell.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CellTextFieldWidth 180.0
#define MarginBetweenControls 20.0

@interface TextFormCell : UITableViewCell {
    UITextField *textField;
}

@property (nonatomic, retain) UITextField *textField;

@end
