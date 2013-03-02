//
//  Location.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Location.h"


@implementation Location
@synthesize name = _name;
@synthesize address = _address;
@synthesize coordinate = _coordinate;

-(id) initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate{
    if( self = [super init]){
        _name = [name copy];
        _address = [address copy];
        _coordinate = coordinate;
    }
    return self;
}

- (NSString*) title{
    return _name;
}

-(NSString*) subtitle{
    return _address;
}

@end