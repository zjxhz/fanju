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
        self.textLabel.text = @"点击查看更多";
        self.textLabel.font = [UIFont systemFontOfSize:16];
        self.textLabel.textColor = RGBCOLOR(80, 80, 80);
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.hidesWhenStopped = YES;
        [self.contentView addSubview:_activityIndicator];
    }
    
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.textAlignment = UITextAlignmentCenter;
//    self.textLabel.center = self.center;
    [_activityIndicator sizeToFit];
    _activityIndicator.center=self.contentView.center;
}

- (void)setObject:(id)object {
    [super setObject:object];
    LoadMoreTableItem *item = object;
    if (item.loading) {
        [_activityIndicator startAnimating];
        self.textLabel.hidden = YES;
    } else{
        [_activityIndicator stopAnimating];
        self.textLabel.text = @"点击查看更多";
        self.textLabel.hidden = NO;
    }
}

@end
