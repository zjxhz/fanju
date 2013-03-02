//
//  LoadMoreTableItem.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoadMoreTableItem.h"
#import "NSDictionary+ParseHelper.h"

@implementation LoadMoreTableItem

-(id)initWithResult:(NSDictionary*)result fromBaseURL:(NSString*)baseURL{
    if (self = [super init]) {
        self.text = @"加载更多";
        _offset = [result offset];
        _amount = [result totalCount];
        _limit = [result limit];
        _baseURL = baseURL;

    }
    return self;

}
-(BOOL)hasMore{
    if (_limit  == 0) {
        return NO;
    }
    return _offset + _limit < _amount;
}

-(NSString*)nextPageURL{
    if (![self hasMore]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@&offset=%d", _baseURL, _offset + _limit];
}

-(void)setLoading:(BOOL)loading{
    _loading = loading;
    _text = _loading ? @"加载中……" : @"加载更多";
}

@end
