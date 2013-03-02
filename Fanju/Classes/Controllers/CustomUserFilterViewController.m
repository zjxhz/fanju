//
//  CustomUserFilterViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CustomUserFilterViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CustomUserFilterViewController ()

@end

@implementation CustomUserFilterViewController
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
    }
    return self;
}

-(void)dismiss:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    okbutton.layer.cornerRadius = 10;
    okbutton.clipsToBounds = YES;
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



-(IBAction)confirm:(id)sender{
    int minutes = 15;
    switch (seen_within.selectedSegmentIndex) {
        case 0:
            minutes = 15;
            break;
        case 1:
            minutes = 60;
            break;
        case 2:
            minutes = 60 * 24;
            break;
        case 3:
            minutes = 60 * 72;
            break;
        default:
            break;
    }
    filter = [NSString stringWithFormat:@"seen_within_minutes=%d", minutes];
    if(gender.selectedSegmentIndex > 0){
        filter =  [NSString stringWithFormat:@"%@&gender=%d", filter, gender.selectedSegmentIndex -1];
    }
    [delegate filterSelected:filter];
    [self dismissViewControllerAnimated:YES completion:^(void){
        
    }];
}


@end
