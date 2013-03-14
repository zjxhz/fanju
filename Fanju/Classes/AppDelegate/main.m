//
//  main.m
//  Fanju
//
//  Created by Xu Huanze on 3/2/13.
//  Copyright (c) 2013 Xu Huanze. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

CFAbsoluteTime StartTime;

int main(int argc, char *argv[])
{
    StartTime = CFAbsoluteTimeGetCurrent();
    @autoreleasepool {        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}