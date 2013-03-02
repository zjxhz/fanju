//
//  Tag.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserTag.h"
#import "ModelHelper.h"


@implementation UserTag
@synthesize uID = _uID, name = _name, imageUrl = _imageUrl;


- (UserTag*)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _uID = [[data objectForKey:@"id"] intValue];
        _name = [data objectForKey:@"name"];
        _imageUrl = [data objectForKey:@"image_url"];
    }
    
    return self;
}

+ (UserTag*)tagWithName:(NSString*)name{
    UserTag* tag = [[UserTag alloc] init];
    tag.name = name;
    return tag;
}

-(BOOL) isEqual:(id)object{
    if ([object isKindOfClass:[self class]]) {
        UserTag* anotherTag = object;
        return _uID == anotherTag.uID; 
    }
    return NO;
}

- (NSUInteger)hash{
    return _uID;
}

+(NSString*) tagsToString:(NSArray*)tags{
    NSMutableString *tagStr = [[NSMutableString alloc] init];
    for (int i = 0; i < tags.count; ++i) {
        UserTag *tag = [tags objectAtIndex:i];
        [tagStr appendString:tag.name];
        if (i != tags.count - 1) {
            [tagStr appendString:@" "];
        }
    }
    return tagStr;
}

-(NSString*)description{
    return self.name;
}

#pragma mark _
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeInt:_uID forKey:@"uID"];
    [coder encodeObject:_imageUrl  forKey:@"image_url"];
}

- (id)initWithCoder:(NSCoder *)coder{
    if(self) {
        _name = [coder decodeObjectForKey:@"name"];
        _uID =  [coder decodeIntForKey:@"uID"];
        _imageUrl =  [coder decodeObjectForKey:@"image_url"];
    }
    
    return self;
}

@end
