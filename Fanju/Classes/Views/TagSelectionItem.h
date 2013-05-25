//
//  TagSelectionItem.h
//  Fanju
//
//  Created by Xu Huanze on 5/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TTTableItem.h"
#import "Tag.h"
@interface TagSelectionItem : TTTableItem
@property(nonatomic, strong) Tag* tag;
@property(nonatomic) BOOL selected;
@end
