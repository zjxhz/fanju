//
//  TagSelectionDataSource.m
//  Fanju
//
//  Created by Xu Huanze on 5/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TagSelectionDataSource.h"
#import "Tag.h"
#import "TagSelectionCell.h"
#import "TagSelectionItem.h"
@implementation TagSelectionDataSource
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object{
    if ([object isKindOfClass:[TagSelectionItem class]]) {
        return [TagSelectionCell class];
    }
    return [super tableView:tableView cellClassForObject:object];
}
@end
