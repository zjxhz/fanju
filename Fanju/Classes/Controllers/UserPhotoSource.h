//
//  UserPhotoSource.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>

//@interface UserPhoto : NSObject <TTPhoto> {
//    NSString* _URL;
//}
//
//- (id)initWithURL:(NSString*)URL size:(CGSize)size ;
//@end



@interface UserPhotoSource : NSObject <TTPhotoSource>
@property(nonatomic, retain) NSArray* photoes;

@end
