//
//  OverlayViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/15/12.
//
//

#import "OverlayViewController.h"

@interface OverlayViewController ()

@end

@implementation OverlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.hidden = YES;
        self.view.userInteractionEnabled = NO;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

+(OverlayViewController*)sharedOverlayViewController{
    static OverlayViewController* instance;
    if (!instance) {
        instance = [[OverlayViewController alloc] init];
    }
    return instance;
}
@end
