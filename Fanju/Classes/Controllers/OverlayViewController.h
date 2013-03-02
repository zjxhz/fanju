//
//  OverlayViewController.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/15/12.
//
//

#import <UIKit/UIKit.h>
//An transparent view controller that is used to present a modal view so the original view can be preserved
@interface OverlayViewController : UIViewController

+(OverlayViewController*)sharedOverlayViewController;
@end
