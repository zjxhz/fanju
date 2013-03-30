//
//  MapHelper.h
//  Fanju
//
//  Created by Xu Huanze on 3/26/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapKit/MapKit.h"

@interface MapHelper : NSObject
+(void)launchRouteTo:(CLLocationCoordinate2D)coordinate withName:(NSString*)name;
@end
