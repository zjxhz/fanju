//
//  EOMessage.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/24/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EOMessage : NSManagedObject

@property (nonatomic, retain) NSString * sender;
@property (nonatomic, retain) NSString* receiver;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSString* type;
@property (nonatomic, retain) NSString* node;//pubsub node
@property (nonatomic, retain) NSString* payload; //pubsub payload
-(id)initWithSender:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message at:(NSDate*)time;
-(id)initWithSender:(NSString*)sender receiver:(NSString*)receiver message:(NSString*)message;
@end
