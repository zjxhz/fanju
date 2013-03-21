//
//  UserTagsCell.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserTag.h"

@interface UserTagsCell : UITableViewCell{
    NSMutableArray* _tagLabels;
}
@property(nonatomic, weak) NSArray* tags;
@property(nonatomic, readonly) UIButton* showAllButton;
@property(nonatomic, readonly) NSInteger cellHeight;
@end
