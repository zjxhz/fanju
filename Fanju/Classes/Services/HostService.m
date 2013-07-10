//
//  HostService.m
//  饭聚
//
//  Created by Xu Huanze on 6/28/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "HostService.h"
#define FANJOIN_SERVER @"fanjoin.com"
#define IFUNJOIN_SERVER @"t.ifunjoin.com"
#define LOCAL_SERVER @"localhost:8000"

typedef enum{
    PRODUCTION, TEST, DEVELOPMENT
} HostType;
@implementation HostService
+(HostService*)service{
    static dispatch_once_t onceToken;
    static HostService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[HostService alloc] init];
    });
    return instance;
}


-(NSString*)host{
    switch ([self hostType]) {
        case PRODUCTION:
            return FANJOIN_SERVER;
        case TEST:
            return IFUNJOIN_SERVER;
        case DEVELOPMENT:
            return LOCAL_SERVER;
        default:
            break;
    }
    return nil;
}

-(HostType)hostType{
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"FanjuHostType"] integerValue];
//    if ([host caseInsensitiveCompare:@"development"] == NSOrderedSame) {
//        return DEVELOPMENT;
//    } else if ([host caseInsensitiveCompare:@"test"] == NSOrderedSame){
//        return TEST;
//    } else
//    return PRODUCTION;
}

-(NSString*)xmppHost{
    switch ([self hostType]) {
        case PRODUCTION:
            return FANJOIN_SERVER;
        case TEST:
            return @"ifunjoin.com";
        case DEVELOPMENT:
            return @"wayne.local";
        default:
            break;
    }
    return nil;
}

-(NSString*)weiboAppKey{
    switch ([self hostType]) {
        case PRODUCTION:
            return @"2295468526";
        case TEST:
            return @"1086545555";
        default:
            break;
    }
    return nil;
}

-(NSString*)weiboSecret{
    switch ([self hostType]) {
        case PRODUCTION:
            return @"5991184a22eaff8d2b1149bcf1b1ff91";
        case TEST:
            return @"edc858db52e5c2bc803010a81b183c5d";
        default:
            return nil;
    }
}

-(NSString*)weiboRedirectUri{
    switch ([self hostType]) {
        case PRODUCTION:
            return @"http://fanjoin.com/login/weibo/";
        case TEST:
            return @"http://t.ifunjoin.com/login/weibo/";
        default:
            return nil;
    }
}


@end
