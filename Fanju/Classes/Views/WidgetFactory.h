//
//  WidgetFactory.h
//  Fanju
//
//  Created by Xu Huanze on 3/19/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WidgetFactory : NSObject
+(WidgetFactory*)sharedFactory;
-(UIBarButtonItem*)backButtonWithTarget:(id)target action:(SEL)action;
-(UIView*)titleViewWithTitle:(NSString*)title;
-(UIBarButtonItem*)normalBarButtonItemWithTitle:(NSString*)title target:(id)target action:(SEL)action;
@end
