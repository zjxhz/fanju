//
//  MealDetailsViewDelegate.h
//  EasyOrder
//
//  Created by Xu Huanze on 2/23/13.
//
//

#import <Three20UI/Three20UI.h>

@interface MealDetailsViewDelegate : TTTableViewVarHeightDelegate
@property(nonatomic) BOOL mapHidden;
@property(nonatomic) NSInteger numberOfParticipantsExcludingHost;
@property(nonatomic) CGFloat detailsHeight;
@end
