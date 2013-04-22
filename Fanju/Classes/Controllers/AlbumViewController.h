//
//  AlbumViewController.h
//  Fanju
//
//  Created by Xu Huanze on 4/18/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfile.h"
#import "ImageUploader.h"

@interface AlbumViewController : UIViewController<ImageUploaderDelegate>
@property(nonatomic, strong) UserProfile* user;
@end
