//
//  ImageUploader.m
//  Fanju
//
//  Created by Xu Huanze on 4/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "ImageUploader.h"
#import "UIImage+Utilities.h"
#import "MBProgressHUD.h"
#import "NetworkHandler.h"
#import "UserProfile.h"
#import "Const.h"
#import "UIImage+Resize.h"

#define LARGE_AVATAR_LENGTH 220
#define MAX_PHOTO_HEIGHT 1920
#define MAX_PHOTO_WIDTH 1280

@implementation ImageUploader{
    UIActionSheet* _imagePickerActions;
    MBProgressHUD* _hud;
    UserProfile* _user;
    UIImagePickerController *_pickerController;
    UIViewController* _viewController;
}
-(id)initWithViewController:(UIViewController*)viewController delegate:(id<ImageUploaderDelegate>)delegate{
    self = [super init];
    _viewController = viewController;
    self.delegate = delegate;
    return self;
}

-(void)uploadImageForUser:(UserProfile*)user option:(ImageUploaderOption)option{
    _user = user;
    self.option = option;
    [self presentImagePicker];
}

-(void)presentImagePicker{
    if (!_imagePickerActions) {
        _imagePickerActions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"相册", nil];
    }
    BOOL toolbarHidden = _viewController.navigationController.toolbar.hidden;
    if (toolbarHidden) {
        [_imagePickerActions showInView:_viewController.view];
    } else {
        [_imagePickerActions showFromToolbar:_viewController.navigationController.toolbar];
    }

}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    CGRect cropRect = CGRectZero;
    if (_option == AVATAR) {
        cropRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
        cropRect = [image convertCropRect:cropRect];
        image = [image croppedImage:cropRect];
    }
    
    CGSize newSize = image.size;
    if (_option == AVATAR && image.size.width > LARGE_AVATAR_LENGTH){
        newSize = CGSizeMake(LARGE_AVATAR_LENGTH, LARGE_AVATAR_LENGTH);
    } else if(_option == PHOTO){
        CGFloat ratio = image.size.height / image.size.width;
        if (ratio > 1.5 && image.size.height > MAX_PHOTO_HEIGHT) { //
            newSize = CGSizeMake(image.size.width * (MAX_PHOTO_HEIGHT / image.size.height), MAX_PHOTO_HEIGHT);
        } else if(image.size.width > MAX_PHOTO_WIDTH){
            newSize = CGSizeMake(MAX_PHOTO_WIDTH, image.size.height * (MAX_PHOTO_WIDTH/ image.size.width));
        }
    }
    NSLog(@"crop and resizing - cropRect:%@ ==> %@ -> %@",
          NSStringFromCGRect(cropRect),
          NSStringFromCGSize(image.size),
          NSStringFromCGSize(newSize));
    
    if (!CGSizeEqualToSize(image.size, newSize)) {
        image = [image imageScaledToSize:newSize];
    }

    
    _hud = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
	_hud.mode = MBProgressHUDModeAnnularDeterminate;
    NSString* filename  = [NSString stringWithFormat:@"%d_%@_%.0f.jpg", _user.uID, _option == AVATAR ? @"a" : @"p", [[NSDate date] timeIntervalSince1970] * 1000 ];
    if (_option == AVATAR) {
        [self doChangeAvatar:image withName:filename];
    } else {
        [self doAddPhoto:image withName:filename];
    }
}


-(void)doAddPhoto:(UIImage*) image withName:(NSString*)filename{
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%d/photos/", _user.uID] success:^(id obj){
        NSDictionary* result = obj;
        if ([[result objectForKey:@"status"] isEqualToString:@"OK"]) {
            [_delegate didUploadPhoto:image withData:result];
        }
        else {
            _hud.labelText = @"上传失败";
            [_delegate didFailUploadPhoto:image];
        }
        [_hud hide:YES afterDelay:1];
        [_pickerController dismissModalViewControllerAnimated:YES];
    } failure:^{
        _hud.labelText = @"上传失败";
        [_hud hide:YES afterDelay:1];
        [_pickerController dismissModalViewControllerAnimated:YES];
        NSLog(@"failed to upload images");
        [_delegate didFailUploadPhoto:image];
    } progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
        _hud.progress = totalBytesLoaded * 1.0 / totalBytesExpected;
    }];
}

-(void)doChangeAvatar:(UIImage*)image withName:(NSString*)filename{
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%d/avatar/", _user.uID]
                                     success:^(id obj) {
                                         NSLog(@"avatar updated");
                                         [_hud hide:YES];
                                         NSDictionary* data = obj;
                                         [_delegate didUploadAvatar:image withData:data];
                                         [_viewController dismissModalViewControllerAnimated:YES];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:AVATAR_UPDATED_NOTIFICATION object:[_user avatarFullUrl]];
                                     } failure:^{
                                         NSLog(@"failed to update avatar");
                                         _hud.labelText = @"上传失败";
                                         [_hud hide:YES afterDelay:1];
                                         [_delegate didFailUploadAvatar:image];
                                         [_viewController dismissModalViewControllerAnimated:YES];
                                     }progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
                                         _hud.progress = totalBytesLoaded * 1.0 / totalBytesExpected;
                                     }];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(_imagePickerActions == actionSheet){
        if(!_pickerController){
            _pickerController = [[UIImagePickerController alloc] init];
            _pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }

        if (buttonIndex == 0) {
            _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else if (buttonIndex == 2){
            return;
        }
        _pickerController.delegate = self;
        _pickerController.allowsEditing = (_option == AVATAR);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_viewController presentModalViewController:_pickerController animated:YES];
        });
        
    }
}



@end
