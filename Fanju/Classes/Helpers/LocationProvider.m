//
//  LocationProvider.m
//  iVideo2
//
//  Created by Liu Xiaozhi on 7/21/10.
//  Copyright 2010 Vobile Inc. All rights reserved.
//

#import "LocationProvider.h"
#import "GCDSingleton.h"

#define TIME_INTERVAL 10*60
@interface LocationProvider (){
    location_updated updated_blocked;
    location_update_failed update_failed_block;
}
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
    [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(scheduledUpdate) userInfo:nil repeats:YES];
}

-(void)scheduledUpdate{
    DDLogVerbose(@"scheduling location update...");
    [self updateLocation];
}

-(void)updateLocation{
    [self.lm startUpdatingLocation];
}

-(void)updateLocationWithSuccess:(location_updated)success_block orFailed:(location_update_failed)failed{
    updated_blocked = success_block;
    update_failed_block = failed;
    [self updateLocation];
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager: (CLLocationManager *) manager 
	didUpdateToLocation: (CLLocation *) newLocation 
		   fromLocation: (CLLocation *) oldLocation{
    DDLogVerbose(@"location updated from %@ to %@", self.lastLocation, newLocation);
    
    if (updated_blocked) {
        DDLogVerbose(@"call block after obtaining location");
        updated_blocked(newLocation);
        updated_blocked = nil;
    }
    
    self.lastLocation = newLocation;
    NSDate* updatedTime = [NSDate date];
    if ([updatedTime timeIntervalSinceDate:_lastLocationUpdatedTime] < 5) {
        DDLogVerbose(@"updating too often, just ignore");
        return;
    } else {
        DDLogVerbose(@"location updated at %@, previous updated at: %@", updatedTime, _lastLocationUpdatedTime );
        [self.locationDelegate finishObtainingLocation:newLocation];
    }
    _lastLocationUpdatedTime = [NSDate date];
    [self.lm stopUpdatingLocation];

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	[self.locationDelegate failedObtainingLocation];
    DDLogError(@"failed to obtain location with error: %@", error);
    [self.lm stopUpdatingLocation];
    if (update_failed_block) {
        update_failed_block();
        update_failed_block = nil;
    }

}
@end
