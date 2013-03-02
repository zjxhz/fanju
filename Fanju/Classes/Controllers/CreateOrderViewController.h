//
//  CreateOrderView.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "MealInfo.h"
@protocol CreateOrderDelegate
-(void) orderCeatedWithUser:(UserProfile*)user numberOfPersons:(NSInteger)num_persons;
@end

@interface CreateOrderViewController : TTTableViewController <UITableViewDelegate, UIPickerViewDelegate, UIAlertViewDelegate>{
    NSInteger _numberOfPersons;
    TTTableCaptionItem* _priceItem;
    TTTableCaptionItem* _totalPriceItem; 
    TTTableControlItem *_numberOfPersonsItem ;
    UIStepper *_stepper;
    UIButton *_confirmButton;
}

@property(nonatomic, strong) MealInfo *mealInfo;
@property(nonatomic, readonly) UIView *tabBar; //don't change the name, it will be used as a selector
@property(nonatomic, assign) id<CreateOrderDelegate> delegate;
@end
