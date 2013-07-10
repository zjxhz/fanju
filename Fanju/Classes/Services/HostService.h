//
//  HostService.h
//  饭聚
//
//  Created by Xu Huanze on 6/28/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HostService : NSObject
+(HostService*)service;
-(NSString*)host;
-(NSString*)xmppHost;
-(NSString*)weiboAppKey;
-(NSString*)weiboSecret;
-(NSString*)weiboRedirectUri;
@end
