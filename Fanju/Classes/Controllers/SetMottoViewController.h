//
//  SetMottoViewController.h
//  Fanju
//
//  Created by Xu Huanze on 5/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SetMottoDelegate
-(void)mottoDidSet:(NSString*)motto;
@end


@interface SetMottoViewController : UIViewController<UITextViewDelegate>
@property(nonatomic, weak) id<SetMottoDelegate> mottoDelegate;
-(void)setMotto:(NSString*)motto;
@end
