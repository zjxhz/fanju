//
//  URLService.h
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLService : NSObject
+(NSString*)absoluteApiURL:(NSString *)url,...;
+(NSString*)absoluteURL:(NSString*)url;
@end
