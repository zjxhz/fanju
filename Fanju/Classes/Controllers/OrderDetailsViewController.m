//
//  OrderDetailsViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OrderDetailsViewController.h"
#import "Const.h"

@interface OrderDetailsViewController ()

@end

@implementation OrderDetailsViewController
@synthesize restaurant = _restaurant, time = _time, mealImage = _mealImage, meal = _meal, code = _code, numerOfPersons = _numerOfPersons, codeLabel = _codeLabel;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mealImage = [[TTImageView alloc] initWithFrame:CGRectMake(8, 8, 65, 65)];
        [self.view addSubview:_mealImage];
        self.title = @"订单详情";
    }
    return self;
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _restaurant.text = [NSString stringWithFormat:@"%@：%d人", _meal.restaurant.name, _numerOfPersons];
    _time.text = [NSString stringWithFormat:@"%@", _meal.time];
    [_mealImage setUrlPath:[NSString stringWithFormat:@"http://%@%@", EOHOST, _meal.photoURL]];
    _codeLabel.text = _code;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
