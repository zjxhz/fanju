//
//  NumberOfParticipantsCell.h
//  Fanju
//
//  Created by Xu Huanze on 4/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AKSegmentedControl.h"

@interface NumberOfParticipantsCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UILabel* numberLabel;
@property(nonatomic, strong) AKSegmentedControl* segControll;
@end
