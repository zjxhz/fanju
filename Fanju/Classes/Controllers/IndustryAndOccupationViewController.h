//
//  IndustryAndOccupationViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/15/13.
//
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
@protocol IndustryAndOccupationViewControllerDelegate
-(void)occupationUpdated:(NSString*)occupation withIndustry:(NSString*)industry;
@end

@interface IndustryAndOccupationViewController : UITableViewController<UIGestureRecognizerDelegate, UITextFieldDelegate>
@property(nonatomic, strong) id<IndustryAndOccupationViewControllerDelegate> delegate;
- (id)initWithIndustry:(NSString*)industry andOccupation:(NSString*)occupation;
@end
