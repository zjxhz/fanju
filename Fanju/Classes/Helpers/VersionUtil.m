//
//  VersionUtil.m
//  Fanju
//
//  Created by Xu Huanze on 11/20/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "VersionUtil.h"

@implementation VersionUtil
+(BOOL)isiOS7{
    return [[[UIDevice currentDevice] systemVersion] doubleValue] >= 7;
}

@end
