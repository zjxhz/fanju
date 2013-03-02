//
//  CommentTableItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CommentTableItem.h"

@implementation CommentTableItem
@synthesize user=_user;
@synthesize comment = _comment;

+ (id)itemFromUser:(UserProfile*)user withComment:(NSString*)comment{
    CommentTableItem *item = [[self alloc] init];
    item.user = user;
    item.comment = comment;
    return item;
}


#pragma mark -
#pragma mark NSObject
- (id)init {  
	if (self = [super init]) {  
		_user = nil;
        _comment = nil;
	}
    
	return self;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {  
        self.user = [decoder decodeObjectForKey:@"user"];
        self.comment = [decoder decodeObjectForKey:@"comment"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {  
    [super encodeWithCoder:encoder];
    
    if (self.user) {
        [encoder encodeObject:self.user forKey:@"user"];
    }
    
    if (self.comment){
        [encoder encodeObject:self.comment forKey:@"comment"];
    }
}
@end
