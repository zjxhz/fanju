//
//  ArchivedMessageService.h
//  Fanju
//
//  Created by Xu Huanze on 5/7/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchivedMessageService : NSObject
+(ArchivedMessageService*)shared;
-(void)retrieveConversations;
@end
