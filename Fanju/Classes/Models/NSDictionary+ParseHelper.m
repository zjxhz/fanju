//
//  NSDictionary+ParseHelper.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+ParseHelper.h"
#import "Const.h"
@implementation NSDictionary (ParseHelper)

- (id)objectForKeyInFields:(id)aKey {
    return [[self objectForKey:@"fields"] objectForKey:aKey];
}

- (id)objectForKeyInObjects {
    return [self objectForKey:@"objects"];
}

//we cannot fully trust nextPageUrl as tastypie framework has problems to deal with nested elements
- (NSString*) nextPageUrl{
    NSDictionary* meta = [self objectForKey:@"meta"];
    NSString* nextPageUrl = [meta objectForKey:@"next"];
    if ([nextPageUrl isKindOfClass:[NSNull class]]) {
        return nil; 
    } else {
        return [NSString stringWithFormat:@"http://%@%@",EOHOST, nextPageUrl];
    }
}

- (NSInteger) totalCount{
    NSDictionary* meta = [self objectForKey:@"meta"];
    return [[meta objectForKey:@"total_count"] intValue];
}

- (NSInteger) limit{
    NSDictionary* meta = [self objectForKey:@"meta"];
    return [[meta objectForKey:@"limit"] intValue];
}

- (NSInteger) offset{
    NSDictionary* meta = [self objectForKey:@"meta"];
    return [[meta objectForKey:@"offset"] intValue];
}
@end
