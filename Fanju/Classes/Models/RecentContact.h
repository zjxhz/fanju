//
//  RecentContact.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 12/3/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RecentContact : NSManagedObject

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * contact;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * unread;

@end
