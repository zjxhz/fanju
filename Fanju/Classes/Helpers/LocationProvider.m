//
//  LocationProvider.m
//  iVideo2
//
//  Created by Liu Xiaozhi on 7/21/10.
//  Copyright 2010 Vobile Inc. All rights reserved.
//

#import "LocationProvider.h"
#import "GCDSingleton.h"

@interface LocationProvider ()
@property (nonatomic, strong) id<LocationProviderDelegate> locationDelegate;
@property (nonatomic, strong) CLLocationManager *lm;
@end

@implementation LocationProvider

@synthesize locationDelegate = _locationDelegate;
@synthesize lastLocationUpdatedTime = _lastLocationUpdatedTime;
@synthesize lm = _lm;
@synthesize lastLocation = _lastLocation;

+ (LocationProvider *)sharedProvider
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (void)obtainCurrentLocation:(id<LocationProviderDelegate>)aDelegate {
	self.locationDelegate = aDelegate;
	
	self.lm = [[CLLocationManager alloc] init];
    self.lm.delegate = self;
    self.lm.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self updateLocation];
    [NSTimer scheduledTimerWithTimeInterval:10*60 target:self selector:@selector(updateLocation) userInfo:nil repeats:YES];
}

-(void)updateLocation{
    [self.lm startUpdatingLocation];
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager: (CLLocationManager *) manager 
	didUpdateToLocation: (CLLocation *) newLocation 
		   fromLocation: (CLLocation *) oldLocation{
	
    self.lastLocation = newLocation;
    _lastLocationUpdatedTime = [[NSDate alloc] init];
    
	[self.locationDelegate finishObtainingLocation:self.lastLocation];
	
    [self.lm stopUpdatingLocation]; 
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	[self.locationDelegate failedObtainingLocation];
    NSLog(@"failed to obtain location with error: %@", error);
    [self.lm stopUpdatingLocation];
}
@end
