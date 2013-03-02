//
//  UserTableItem.m
//  EasyOrder
//
//  Created by igneus on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserTableItem.h"

@implementation UserTableItem

@synthesize profile = _profile;
@synthesize withAddButton = _withAddButton;

+ (id)itemWithProfile:(UserProfile*)profile withAddButton:(BOOL)withAdd {
    UserTableItem *item = [[self alloc] init];
	item.profile = profile;
    item.withAddButton = withAdd;
    
	return item;
}

#pragma mark -
#pragma mark NSObject

- (id)init {  
	if (self = [super init]) {  
		_profile = nil;
        _withAddButton = NO;
	}
    
	return self;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {  
        self.profile = [decoder decodeObjectForKey:@"profile"];
        self.withAddButton = [[decoder decodeObjectForKey:@"withAddButton"] boolValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {  
    [super encodeWithCoder:encoder];
    
    if (self.profile) {
        [encoder encodeObject:self.profile
                       forKey:@"profile"];
        [encoder encodeObject:[NSNumber numberWithInt:self.withAddButton]
                       forKey:@"withAddButton"];
    }
}


@end
