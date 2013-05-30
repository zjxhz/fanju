//
//  DatePickerWithToolbarView.m
//  Fanju
//
//  Created by Xu Huanze on 5/25/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "DatePickerWithToolbarView.h"
#define DateTimePickerPickerHeight 216
#define DateTimePickerToolbarHeight 44

@interface DatePickerWithToolbarView()
@property (nonatomic, assign) CGRect originalFrame;
@end

@implementation DatePickerWithToolbarView
- (id) initWithFrame: (CGRect) frame {
    if ((self = [super initWithFrame: frame])) {
        self.originalFrame = frame;
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat width = self.bounds.size.width;
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, width, DateTimePickerToolbarHeight)];
        toolbar.barStyle = UIBarStyleBlackOpaque;
        
        
        UIDatePicker *picker = [[UIDatePicker alloc] initWithFrame: CGRectMake(0, DateTimePickerToolbarHeight, width, DateTimePickerPickerHeight)];
        [self addSubview: picker];
        

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action: @selector(donePressed)];
        toolbar.items = [NSArray arrayWithObject: doneButton];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action: @selector(cancelPressed)];
  
        
        UIBarButtonItem* flexiSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        toolbar.items = @[cancelButton, flexiSpace, doneButton];
        
        [self addSubview: toolbar];
        
        _picker = picker;
    }
    return self;
}


- (void)setMode: (UIDatePickerMode) mode {
    _picker.datePickerMode = mode;
}

- (void) donePressed {
    [self setHidden:YES animated:YES];
    [_datePickerDelegate datePicked:_picker.date];
}

-(void) cancelPressed{
    [self setHidden:YES animated:YES];
    [_datePickerDelegate datePickCanceled];
}

- (void)setHidden:(BOOL) hidden animated:(BOOL)animated {
    CGRect newFrame = self.originalFrame;
    newFrame.origin.y += hidden ? DateTimePickerHeight : 0;
    if (animated) {
        [UIView beginAnimations: @"animateDateTimePicker" context: nil];
        [UIView setAnimationDuration: 0.5];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
        
        self.frame = newFrame;
        [UIView commitAnimations];
    } else {
        self.frame = newFrame;
    }
}

@end