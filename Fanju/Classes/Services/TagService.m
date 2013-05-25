//
//  TagService.m
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "TagService.h"
#import "Tag.h"

@implementation TagService
+(TagService*)service{
    static dispatch_once_t onceToken;
    static TagService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[TagService alloc] init];
    });
    return instance;
}

+(NSString*)textOfTags:(NSArray*)tags{
    NSMutableString* text = [[NSMutableString alloc] init];
    for (int i = 0; i < tags.count; ++i) {
        Tag* tag = tags[i];
        [text appendString:tag.name];
        if (i != tags.count - 1) {
            [text appendString:@" / "];
        }
    }
    return text;
}

+(NSString*) tagsToString:(NSArray*)tags{
    NSMutableString *tagStr = [[NSMutableString alloc] init];
    for (int i = 0; i < tags.count; ++i) {
        Tag *tag = [tags objectAtIndex:i];
        [tagStr appendString:tag.name];
        if (i != tags.count - 1) {
            [tagStr appendString:@" "];
        }
    }
    return tagStr;
}
@end
