//
//  RestaurantListViewController.h
//  EasyOrder
//
//  Created by igneus on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonTableViewController.h"
#import <MapKit/MapKit.h>

@interface RestaurantListViewController : CommonTableViewController <MKMapViewDelegate> {
@private
    BOOL displayListMode;
}

@end
