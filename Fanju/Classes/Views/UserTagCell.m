//
//  UserTagCell.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 2/1/13.
//
//

#import "UserTagCell.h"

@implementation UserTagCell


#pragma mark -
#pragma mark TTTableViewCell

- (id)object {
	return _userTag;
}

- (void)setObject:(id)object {
	if (_userTag != object) {
		[super setObject:object];
        UserTag* tag = object;
        self.textLabel.text = tag.name;
    }
}

@end
