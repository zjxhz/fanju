//
//  TagSelectionItem.m
//  Fanju
//
//  Created by Xu Huanze on 5/23/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TagSelectionItem.h"

@implementation TagSelectionItem
-(BOOL)isSaved{
    return _tag != nil && _tag.tID != nil;
}
@end
