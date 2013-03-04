//
//  Message.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/24/12.
//
//

#import "EOMessage.h"


@implementation EOMessage

@dynamic sender;
@dynamic receiver;
@dynamic message;
@dynamic time;
@dynamic type;
@dynamic node;
@dynamic payload;

-(id)initWithSender:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message{
    return [self initWithSender:sender receiver:receiver message:message at:[NSDate date]];
}

-(id)initWithSender:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message at:(NSDate*)time{
    if (self = [super init]) {
        self.sender = sender;
        self.receiver = receiver;
        self.message = message;
        self.time = time;
    }
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@->%@(%@): %@", self.sender, self.receiver, self.time, self.message];
}
@end
