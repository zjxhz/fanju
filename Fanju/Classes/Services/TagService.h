//
//  TagService.h
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TagService : NSObject
+(TagService*)service;
+(NSString*)textOfTags:(NSArray*)tags;
+(NSString*) tagsToString:(NSArray*)tags;
@end
