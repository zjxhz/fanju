//
//  GuestUser.h
//  Fanju
//
//  Created by Xu Huanze on 5/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface GuestUser : NSObject
@property(nonatomic, strong) User* host;
@end
