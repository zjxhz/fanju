//
//  EventFactory.h
//  Fanju
//
//  Created by Xu Huanze on 3/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EOMessage.h"

@interface EventFactory : NSObject
+(EventFactory*)sharedFactory;
-(id)createEvent:(EOMessage*)message;
@end
