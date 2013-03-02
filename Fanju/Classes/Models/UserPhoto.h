//
//  UserPhoto.h
//  EasyOrder
//
//  Created by 徐 浣泽 on 9/29/12.
//
//

#import <Foundation/Foundation.h>

@interface UserPhoto : NSObject <NSCoding>
@property (nonatomic, copy) NSString *url;
@property (nonatomic) int pID;
@property (nonatomic, copy) NSString* thumbnailUrl;


- (UserPhoto *)initWithData:(NSDictionary *)data;
+ (UserPhoto *)photoWithData:(NSDictionary *)data;
-(NSString*)fullUrl;
-(NSString*)thumbnailFullUrl;
@end
