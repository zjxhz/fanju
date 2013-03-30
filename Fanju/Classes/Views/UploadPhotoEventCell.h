//
//  UploadPhotoEventCell.h
//  Fanju
//
//  Created by Xu Huanze on 3/29/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageview.h"
#import "SimpleUserEventCell.h"

@interface UploadPhotoEventCell: SimpleUserEventCell
@property(nonatomic, weak) IBOutlet UIImageView* photoBg;
@property(nonatomic, weak) IBOutlet NINetworkImageView* photo;
@end
