//
//  DatePickerWithToolbarView.h
//  Fanju
//
//  Created by Xu Huanze on 5/25/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DateTimePickerHeight 260
@protocol DatePickerViewDelegate

-(void)datePicked:(NSDate*)date;
-(void)datePickCanceled;
@end

@interface DatePickerWithToolbarView : UIView
@property(nonatomic, strong) UIDatePicker *picker;
@property(nonatomic, weak) id<DatePickerViewDelegate> datePickerDelegate;
- (void) setMode: (UIDatePickerMode) mode;
- (void) setHidden: (BOOL) hidden animated: (BOOL) animated;
@end