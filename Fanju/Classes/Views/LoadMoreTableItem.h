//
//  LoadMoreTableItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>

@interface LoadMoreTableItem : TTTableMoreButton
@property(nonatomic)  NSInteger offset;
@property(nonatomic)  NSInteger amount;
@property(nonatomic)  NSInteger limit;

@property NSString* baseURL;
@property(nonatomic) BOOL loading;

-(id)initWithResult:(NSDictionary*)result fromBaseURL:(NSString*)baseURL;
-(BOOL)hasMore;
-(NSString*)nextPageURL;
@end
