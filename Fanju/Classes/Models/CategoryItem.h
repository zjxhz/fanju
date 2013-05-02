//
//  CategoryItem.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderedObject.h"
@interface CategoryItem : NSObject<OrderedObject>
@property NSInteger orderNo;//seq no
@property(nonatomic, copy) NSString* name;

-(CategoryItem*)initWithData:(NSDictionary*)data;
+(CategoryItem*) itemWithData:(NSDictionary*)data;
+(CategoryItem*) dummyCategory;
-(BOOL)isDummy;
@end
