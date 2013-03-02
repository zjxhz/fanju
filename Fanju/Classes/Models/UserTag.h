//
//  Tag.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserTag : NSObject <NSCoding>
- (UserTag*)initWithData:(NSDictionary *)data;
+ (UserTag*)tagWithName:(NSString*)name;
+(NSString*) tagsToString:(NSArray*)tags;
@property NSInteger uID;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, copy) NSString* imageUrl;
@end
