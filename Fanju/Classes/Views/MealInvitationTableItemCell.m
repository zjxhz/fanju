//
//  MealInvitationTableItemCell.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealInvitationTableItemCell.h"
#import "MealTableItem.h"
#import "MealInvitationTableItem.h"
#import "DateUtil.h"
#import "Const.h"
#import "AppDelegate.h"
#import "NetworkHandler.h"
#import "SVProgressHUD.h"
#import "Authentication.h"

@interface MealInvitationTableItemCell(){
    UILabel *_fromLabel;
    UILabel *_topicLabel;
	UILabel *_subtitleLabel;
    UIImageView *_imgView;
    UIView *_frame;
    UILabel *_restaurant;
    UIView *_peopleFrame;
    UIButton *_accetButton;
    UIButton *_rejectButton;
}
@end

@implementation MealInvitationTableItemCell


+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	return 175.0;
}

- (void)buildUI
{
    _frame = [[UIView alloc] initWithFrame:CGRectMake(0, 0,320,170)];
    [self.contentView addSubview:_frame];
    

    _fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, 300, 20)];
    [_fromLabel setFont:[UIFont systemFontOfSize:12]];
    [_frame addSubview:_fromLabel];

    
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 22, 120, 111)];
    [_imgView setContentMode:UIViewContentModeScaleAspectFill];
    _imgView.clipsToBounds = YES; 
    [_frame addSubview:_imgView];
    
    _topicLabel = [[UILabel alloc] initWithFrame:CGRectMake((_frame.frame.size.width - 100) / 2, 70, 200, 50)];
    [_topicLabel setBackgroundColor:[UIColor clearColor]];
    [_topicLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [_topicLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_topicLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake((_frame.frame.size.width - 100) / 2, 100, 200, 30)];
    [_subtitleLabel setBackgroundColor:[UIColor clearColor]];
    [_subtitleLabel setFont:[UIFont italicSystemFontOfSize:12]];
    [_subtitleLabel setTextAlignment:UITextAlignmentCenter];
    [_frame addSubview:_subtitleLabel];
    

    _peopleFrame = [[UIView alloc] initWithFrame:CGRectMake(124, 22, 240, 57)];
    [_peopleFrame setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [_frame addSubview:_peopleFrame];
    
    _accetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _accetButton.frame = CGRectMake(70, 140, 70, 30);
    [_accetButton.titleLabel setBackgroundColor:[UIColor greenColor]];
    [_accetButton setTitle:NSLocalizedString(@"Accept", nil) forState:UIControlStateNormal] ;
    [_accetButton addTarget:self action:@selector(acceptButtonClicked) forControlEvents:UIControlEventTouchDown];
    
    _rejectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _rejectButton.frame = CGRectMake(150, 140, 70, 30);
    [_rejectButton setTitle:NSLocalizedString(@"Reject", nil) forState:UIControlStateNormal]; 
    _rejectButton.tintColor = [UIColor grayColor];
//     [_rejectButton.titleLabel setBackgroundColor:[UIColor grayColor]];
    
    [_frame addSubview:_accetButton];
    [_frame addSubview:_rejectButton];
//    _item = nil;
}

-(void)acceptButtonClicked{
    if(![[Authentication sharedInstance] isLoggedIn]) {        
        // not logged in
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate showLogin];
    } else {
        [self respondToInvitation:YES]; 
    }
}

-(void)rejectButtonClicked{
    if(![[Authentication sharedInstance] isLoggedIn]) {        
        // not logged in
        AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [delegate showLogin];
    } else {
        [self respondToInvitation:NO];
    }
}

-(void)respondToInvitation:(BOOL)accept{
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];
    NSString *userID = currentUser ? [NSString stringWithFormat:@"%d", currentUser.uID] : nil;
    NSString *acceptOrNot = accept ? @"YES" : @"NO";
    NSArray *params = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:acceptOrNot, @"value", @"accept", @"key", nil]];
    [[NetworkHandler getHandler] requestFromURL:[NSString stringWithFormat:@"%@://%@/user/%@/invitation/%d/", HTTPS, EOHOST, userID, [self mealInvitation].mID]
                                         method:POST
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            if ([[obj objectForKey:@"status"] isEqualToString:@"OK"] || [[obj objectForKey:@"status"] isEqualToString:@"NOK"]) {
                                                [SVProgressHUD showSuccessWithStatus:[obj objectForKey:@"info"]];
                                            }
                                        } failure:^{
                                            
                                        }];
}
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2
                    reuseIdentifier:identifier]) {
        [self buildUI];
	}
    
	return self;
}


- (id)object {
	return _item;  
}

- (MealInvitation *) mealInvitation{
    MealInvitationTableItem *mealInvitationTableItem = [self object];
    return mealInvitationTableItem.mealInvitation;
}

- (void)setObject:(id)object {
	if (_item != object) {
		[super setObject:object];
        MealInfo *mealInfo = nil;
        MealInvitation *mealInvitation = nil;
        MealInvitationTableItem *mealInvitationTableItem = object;
        mealInvitation = mealInvitationTableItem.mealInvitation;        
        mealInfo = mealInvitation.meal;
        
        NSString *invitationString = mealInfo.type == THEMES ? NSLocalizedString(@"GatheringInvitation", nil) : NSLocalizedString(@"DatingInvitation", nil);
        NSLog(@"type is: %d, THEMES is: %d", mealInfo.type, THEMES);
        NSString* timePast = [DateUtil humanReadableIntervals:(-[mealInvitation.timestamp timeIntervalSinceNow])];
        [_fromLabel setText:[NSString stringWithFormat:invitationString, mealInvitation.from.username, timePast]];

		// Set the data in various UI elements
		[_topicLabel setText:mealInfo.topic];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterFullStyle];
        [df setLocale:[NSLocale currentLocale]];
		[_subtitleLabel setText:[df stringFromDate:mealInfo.time]];
        
        [_imgView setImage:[UIImage imageNamed:@"thumb.jpg"]];
        [_restaurant setText:mealInfo.restaurant.name];
        
        for (UIView *view in [_peopleFrame subviews]) {
            if ([view isKindOfClass:[TTImageView class]]) {
                [view removeFromSuperview];
            }
        }
        
        int num = [mealInfo.participants count];
        for (int i = 0; i < num; i++) {
            TTImageView *img = [[TTImageView alloc] initWithFrame:CGRectMake(8 + 50 * i, 8, 41, 41)];
            img.style = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] 
                                                next:
                         [TTSolidFillStyle styleWithColor:[UIColor whiteColor] 
                                                     next:[TTContentStyle styleWithNext:
                                                           [TTInnerShadowStyle styleWithColor:RGBACOLOR(0,0,0,0.5) 
                                                                                         blur:6 
                                                                                       offset:CGSizeMake(5, 5) 
                                                                                         next:nil]]]];
            img.contentMode = UIViewContentModeScaleAspectFill; 
            img.clipsToBounds = YES; 
            [img setBackgroundColor:[UIColor clearColor]];
            [img setDefaultImage:[UIImage imageNamed:@"anno.png"]];
            [_peopleFrame addSubview:img];
        }
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
    // Set the size, font, foreground color, background color, ...
    _frame.center = self.contentView.center;
    
}

@end
