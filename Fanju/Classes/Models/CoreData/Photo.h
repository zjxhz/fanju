//
//  Photo.h
//  Fanju
//
//  Created by Xu Huanze on 5/6/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Photo : NSManagedObject

@property (nonatomic, retain) NSNumber * pID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * url;

@end
