//
//  MenuCoverView.m
//  EasyOrder
//
//  Created by igneus on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuCoverView.h"
#import <Three20/Three20.h>
#import "MenuUpdater.h"

@interface MenuCoverView ()
- (void)menuUpdated:(NSNotification*)notif;
@end

@implementation MenuCoverView

#pragma mark - View lifecycle

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuUpdated:) 
                                                     name:MenuDidUpdateNotification
                                                   object:nil];
        
        CGRect rect = [UIScreen mainScreen].applicationFrame;
        [self setFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
        UIImageView *coverImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cover.jpg"]];
        [coverImage setFrame:self.frame];
        [self addSubview:coverImage];
        
        TTSearchlightLabel* label = [[TTSearchlightLabel alloc] init];
        label.text = NSLocalizedString(@"UpdateMenu", nil);
        label.font = [UIFont systemFontOfSize:25];
        label.textAlignment = UITextAlignmentCenter;
        label.contentMode = UIViewContentModeTop;
        label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
        [label sizeToFit];
        label.frame = CGRectMake(0, 240, self.frame.size.width, label.frame.size.height + 40);
        
        [self addSubview:label];
        [label startAnimating];
    }
    return self;
}


- (void)menuUpdated:(NSNotification*)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MenuDidUpdateNotification 
                                                  object:nil];
    [UIView animateWithDuration:0.5
                     animations:^(){
                         CGRect rect = [UIScreen mainScreen].applicationFrame;
                         rect.origin.x = rect.size.width;
                         rect.origin.y = 0;
                         self.frame = rect;
                     }
                     completion:^(BOOL success){
                         [self removeFromSuperview];
                     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
