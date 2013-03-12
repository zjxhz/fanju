//
//  UserPhoto.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 9/29/12.
//
//

#import "UserPhoto.h"
#import "ModelHelper.h"
#import "Const.h"
@implementation UserPhoto

- (UserPhoto *)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        self.pID = [[data objectForKey:@"id"] intValue];
        self.url = [ModelHelper stringValueForKey:@"large" inDictionary:data];
        self.thumbnailUrl = [ModelHelper stringValueForKey:@"thumbnail" inDictionary:data];
    }
    
    return self;
}

+ (UserPhoto *)photoWithData:(NSDictionary *)data {
    return [[UserPhoto alloc] initWithData:data];
}

-(NSString*)fullUrl{
    if (self.url) {
        return [NSString stringWithFormat:@"http://%@%@", EOHOST, self.url];
    } else {
        return nil;
    }
}

-(NSString*)thumbnailFullUrl{
    if (self.thumbnailUrl) {
        return [NSString stringWithFormat:@"http://%@%@", EOHOST, self.thumbnailUrl];
    } else {
        return nil;
    }
}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:self.url forKey:@"photo"];
    [coder encodeInt:self.pID forKey:@"pID"];
}

- (id)initWithCoder:(NSCoder *)coder{
    self.pID = [coder decodeIntegerForKey:@"pID"];
    self.url = [coder decodeObjectForKey:@"photo"];
    return self;
}
@end
