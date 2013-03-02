//
//  LocationProvider.h
//  iVideo2
//
//  Created by Liu Xiaozhi on 7/21/10.
//  Copyright 2010 Vobile Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationProviderDelegate <NSObject>
@optional
-(void)finishObtainingLocation:(CLLocation*)location;
-(void)failedObtainingLocation;
@end

@interface LocationProvider : NSObject <CLLocationManagerDelegate> 

@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, readonly) NSDate *lastLocationUpdatedTime;
+ (LocationProvider *) sharedProvider;
- (void)obtainCurrentLocation:(id<LocationProviderDelegate>)aDelegate;

@end

