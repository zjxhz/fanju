//
//  URLService.m
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "URLService.h"
#import "Const.h"

@implementation URLService
+(NSString*)absoluteApiURL:(NSString *)url,...{
    va_list arguments;
    va_start(arguments, url);
    if ([url hasPrefix:@"/"]) {
        url = [url substringFromIndex:1];
    }
    NSString* absolute = [NSString stringWithFormat:@"http://%@/api/v1/%@", EOHOST, url];
    return [[NSString alloc] initWithFormat:absolute arguments:arguments];
}

+(NSString*)absoluteURL:(NSString*)url{
    if ([url hasPrefix:@"http:"]) {
        return url;
    } else {
        return [NSString stringWithFormat:@"http://%@%@", EOHOST, url];
    }
}
@end
