//
//  MapHelper.m
//  Fanju
//
//  Created by Xu Huanze on 3/26/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "MapHelper.h"

@implementation MapHelper

+(void)launchRouteTo:(CLLocationCoordinate2D)coordinate withName:(NSString*)name{
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
    {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:name];
        
        
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
        [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem]
                       launchOptions:launchOptions];
    } else {
        NSString *route = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%@&daddr=%g,%g", NSLocalizedString(@"CurrentLocation", nil), coordinate.latitude, coordinate.longitude];
        route = [route stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:route]];
    }
}

@end
