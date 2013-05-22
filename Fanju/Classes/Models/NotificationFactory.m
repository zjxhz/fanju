//
//  NotificationFactory.m
//  Fanju
//
//  Created by Xu Huanze on 5/12/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "NotificationFactory.h"


@implementation NotificationFactory{
    NSManagedObjectContext* _mainQueueContext;
}
+(NotificationFactory*)factory{
    static dispatch_once_t onceToken;
    static NotificationFactory* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[NotificationFactory alloc] init];
    });
    return instance;
}

-(id)init{
    if (self = [super init]) {
//        RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
//        _mainQueueContext = store.mainQueueManagedObjectContext;
    }
    return self;
}




@end
