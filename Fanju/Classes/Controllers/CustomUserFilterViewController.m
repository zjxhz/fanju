//
//  CustomUserFilterViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CustomUserFilterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WidgetFactory.h"

#define X_GAP 10

@interface CustomUserFilterViewController (){
    UILabel* _genderLabel;
    AKSegmentedControl* _gender;
    UILabel* _timeLabel;
    AKSegmentedControl* _time;
    UILabel* _timeHelperLabel;
    UIButton* _okButton;
    NSMutableDictionary* _filter;
}

@end

@implementation CustomUserFilterViewController
@synthesize delegate;

-(id) init{
    if (self = [super init]) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
        self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"筛选"];
        self.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"取消" target:self action:@selector(dismiss:)];
        
        _genderLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 200, 20)];
        _genderLabel.text = @"想看到的用户";
        _genderLabel.font = [UIFont systemFontOfSize:17];
        _genderLabel.backgroundColor = [UIColor clearColor];
        _genderLabel.textColor = RGBCOLOR(80, 80, 80);
        [_genderLabel sizeToFit];
        [self.view addSubview:_genderLabel];
        
        
        UIImage* gender_left = [UIImage imageNamed:@"gender_seg_left"];
        UIImage* gender_mid = [UIImage imageNamed:@"gender_seg_mid"];
        UIImage* gender_right = [UIImage imageNamed:@"gender_seg_right"];
        UIImage* gender_left_push = [UIImage imageNamed:@"gender_seg_left_push"];
        UIImage* gender_mid_push = [UIImage imageNamed:@"gender_seg_mid_push"];
        UIImage* gender_right_push = [UIImage imageNamed:@"gender_seg_right_push"];
        UIImage* male = [UIImage imageNamed:@"male_filter"];
        UIImage* female = [UIImage imageNamed:@"female_filter"];
        
        _gender = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(X_GAP, 42, 300, 43)];
        _gender.segmentedControlMode = AKSegmentedControlModeSticky;
        [_gender setSelectedIndex:0];
        UIButton* bl = [self createSegmentButton:@"不限" withNormalImage:gender_left pushImage:gender_left_push];
        UIButton* bm =  [self createSegmentButton:@"男" withNormalImage:gender_mid pushImage:gender_mid_push image:male];
        UIButton* br =  [self createSegmentButton:@"女" withNormalImage:gender_right pushImage:gender_right_push image:female];
        [_gender setButtonsArray:@[bl, bm, br]];
        [self.view addSubview:_gender];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 117, 200, 20)];
        _timeLabel.text = @"出现的时间";
        _timeLabel.font = [UIFont systemFontOfSize:17];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.textColor = RGBCOLOR(80, 80, 80);
        [_timeLabel sizeToFit];
        [self.view addSubview:_timeLabel];
        
        
        UIImage* t0 = [UIImage imageNamed:@"time_seg_0"];
        UIImage* t0p = [UIImage imageNamed:@"time_seg_p0"];
        UIImage* t1 = [UIImage imageNamed:@"time_seg_1"];
        UIImage* t1p = [UIImage imageNamed:@"time_seg_p1"];
        UIImage* t2 = [UIImage imageNamed:@"time_seg_2"];
        UIImage* t2p = [UIImage imageNamed:@"time_seg_p2"];
        UIImage* t3 = [UIImage imageNamed:@"time_seg_3"];
        UIImage* t3p = [UIImage imageNamed:@"time_seg_p3"];

        _time = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(X_GAP, 144, 300, 43)];
        _time.segmentedControlMode = AKSegmentedControlModeSticky;
        [_time setSelectedIndex:3];
        UIButton* b0 = [self createSegmentButton:@"30分钟" withNormalImage:t0 pushImage:t0p];
        UIButton* b1 =  [self createSegmentButton:@"1小时" withNormalImage:t1 pushImage:t1p];
        UIButton* b2 =  [self createSegmentButton:@"1天" withNormalImage:t2 pushImage:t2p];
        UIButton* b3 =  [self createSegmentButton:@"不限" withNormalImage:t3 pushImage:t3p];
        [_time setButtonsArray:@[b0, b1, b2, b3]];
        [self.view addSubview:_time];
        
        _timeHelperLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 203, 320, 20)];
        _timeHelperLabel.text = @"选中时间内登录过饭聚的用户";
        _timeHelperLabel.font = [UIFont systemFontOfSize:14];
        _timeHelperLabel.backgroundColor = [UIColor clearColor];
        _timeHelperLabel.textColor = RGBCOLOR(150, 150, 150);
        _timeHelperLabel.textAlignment = UITextAlignmentCenter;
        [self.view addSubview:_timeHelperLabel];
        
        UIImage* btnImg = [UIImage imageNamed:@"confirm_btn_big"];
        
        _okButton = [[UIButton alloc] initWithFrame:CGRectMake((320 - btnImg.size.width) / 2,
                                                               319, btnImg.size.width, btnImg.size.height)];
        [_okButton setBackgroundImage:btnImg forState:UIControlStateNormal];
        [_okButton setTitle:@"确定" forState:UIControlStateNormal];
        [_okButton addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
        _okButton.titleLabel.textColor = [UIColor whiteColor];
        _okButton.titleLabel.font = [UIFont systemFontOfSize:17];
        _okButton.titleLabel.layer.shadowColor = RGBACOLOR(0, 0, 0, 0.25).CGColor;
        _okButton.titleLabel.layer.shadowOffset = CGSizeMake(0, -2);
        [self.view addSubview:_okButton];
    }
    return self;
}

-(UIButton*)createSegmentButton:(NSString*)title withNormalImage:(UIImage*)normal pushImage:(UIImage*)push{
    return [self createSegmentButton:title withNormalImage:normal pushImage:push image:nil];
}

-(UIButton*)createSegmentButton:(NSString*)title withNormalImage:(UIImage*)normal pushImage:(UIImage*)push image:(UIImage*)image{
    UIButton* b = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, normal.size.width, normal.size.height)];
    b.titleLabel.font = [UIFont systemFontOfSize:14];
    b.titleLabel.textColor = RGBCOLOR(150, 150, 150);
    [b setTitleColor:RGBCOLOR(150, 150, 150) forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState: UIControlStateSelected];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted | UIControlStateSelected];
    [b setTitleShadowColor:RGBACOLOR(0, 0, 0, 0.25) forState:UIControlStateHighlighted];
    [b setBackgroundImage:normal forState:UIControlStateNormal];
    [b setBackgroundImage:push forState:UIControlStateSelected];
    [b setBackgroundImage:push forState:UIControlStateHighlighted];
    [b setBackgroundImage:push forState:UIControlStateSelected | UIControlStateHighlighted];
    if (image) {
        [b setImage:image forState:UIControlStateNormal];
    }
    [b setTitle:title forState:UIControlStateNormal];
    return b;
}

-(void)segmentValueChanged:(UISegmentedControl*)seg{
    
}
-(void)dismiss:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



-(IBAction)confirm:(id)sender{
    _filter = [NSMutableDictionary dictionary];
    int minutes = 0;
    NSInteger selectedIndex = _time.selectedIndexes.firstIndex;
    switch (selectedIndex) {
        case 0:
            minutes = 30;
            break;
        case 1:
            minutes = 60;
            break;
        case 2:
            minutes = 60 * 24;
            break;
        default:
            break;
    }
    if (minutes != 0) {
        _filter[@"seen_within_minutes"]=[NSNumber numberWithInteger:minutes];
    }
    
    if(_gender.selectedIndexes.firstIndex > 0){
        _filter[@"gender"]= [NSNumber numberWithInteger:_gender.selectedIndexes.firstIndex - 1];
    }
    [self dismissViewControllerAnimated:YES completion:^(void){
        [TTURLRequestQueue mainQueue].suspended = NO;
        [delegate filterSelected:_filter];
    }];
//    [self performSelector:@selector(setFilter) withObject:nil afterDelay:0.1];
}

-(void)setFilter{
    
}

@end
