//
//  ImageUploader.h
//  Fanju
//
//  Created by Xu Huanze on 4/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Photo.h"

typedef enum{
    AVATAR, PHOTO
}
ImageUploaderOption;

@protocol ImageUploaderDelegate <NSObject>
@optional
-(void)didUploadPhoto:(Photo*)photo image:(UIImage*)image;
-(void)didFailUploadPhoto:(UIImage*)image;
-(void)didUploadAvatar:(UIImage*)image  withData:(NSDictionary*)data;
-(void)didFailUploadAvatar:(UIImage*)image;
@end


@interface ImageUploader : NSObject<UIImagePickerControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
-(id)initWithViewController:(UIViewController*)viewController delegate:(id<ImageUploaderDelegate>)delegate;
-(void)uploadAvatar;
-(void)uploadPhoto;
@property(nonatomic) ImageUploaderOption option;
@property(nonatomic, weak) id<ImageUploaderDelegate> delegate;
@end
