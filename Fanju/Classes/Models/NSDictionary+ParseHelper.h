//
//  NSDictionary+ParseHelper.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ParseHelper)

- (id)objectForKeyInFields:(id)aKey;
- (id)objectForKeyInObjects;
- (NSString*)nextPageUrl;
- (NSInteger)totalCount;
- (NSInteger)limit;
- (NSInteger)offset;
@end
