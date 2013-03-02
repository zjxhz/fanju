//
//  LoadMoreTableItemCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoadMoreTableItemCell.h"
#import "LoadMoreTableItem.h"

@implementation LoadMoreTableItemCell
@synthesize activityIndicator = _activityIndicator;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];
    if (self) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.hidesWhenStopped = YES;
        [self.contentView addSubview:_activityIndicator];
    }
    
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    [_activityIndicator sizeToFit];
    self.textLabel.textAlignment = UITextAlignmentCenter;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _activityIndicator.frame = CGRectMake(80, 13, _activityIndicator.frame.size.width, _activityIndicator.frame.size.height);
}

- (void)setObject:(id)object {
    [super setObject:object];
    LoadMoreTableItem *item = object;
    self.textLabel.text = item.text;
    if (item.loading) {
        [_activityIndicator startAnimating];
    } else {
        [_activityIndicator stopAnimating];
    }
}

@end
