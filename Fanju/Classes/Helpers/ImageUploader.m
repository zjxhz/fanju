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
#import "Const.h"
#import "UIImage+Resize.h"
#import "URLService.h"
#import "UserService.h"
#import "RestKit.h"
#import "Photo.h"
#define LARGE_AVATAR_LENGTH 220
#define MAX_PHOTO_HEIGHT 1920
#define MAX_PHOTO_WIDTH 1280

@implementation ImageUploader{
    UIActionSheet* _imagePickerActions;
    MBProgressHUD* _hud;
    UIImagePickerController *_pickerController;
    UIViewController* _viewController;
    NSManagedObjectContext* _mainQueueContext;
}
-(id)initWithViewController:(UIViewController*)viewController delegate:(id<ImageUploaderDelegate>)delegate{
    self = [super init];
    _viewController = viewController;
    self.delegate = delegate;
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _mainQueueContext = store.mainQueueManagedObjectContext;
    return self;
}

-(void)uploadAvatar{
    self.option = AVATAR;
    [self presentImagePicker];
}

-(void)uploadPhoto{
    self.option = PHOTO;
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
    DDLogVerbose(@"crop and resizing - cropRect:%@ ==> %@ -> %@",
          NSStringFromCGRect(cropRect),
          NSStringFromCGSize(image.size),
          NSStringFromCGSize(newSize));
    
    if (!CGSizeEqualToSize(image.size, newSize)) {
        image = [image imageScaledToSize:newSize];
    }

    
    _hud = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
	_hud.mode = MBProgressHUDModeAnnularDeterminate;
    NSString* userID = [[UserService service].loggedInUser.uID stringValue];
    NSString* filename  = [NSString stringWithFormat:@"%@_%@_%.0f.jpg", userID, _option == AVATAR ? @"a" : @"p", [[NSDate date] timeIntervalSince1970] * 1000 ];
    if (_option == AVATAR) {
        [self doChangeAvatar:image withName:filename];
    } else {
        [self doAddPhoto:image withName:filename];
    }
}


-(void)doAddPhoto:(UIImage*) image withName:(NSString*)filename{
    NSString* userID = [[UserService service].loggedInUser.uID stringValue];
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%@/photos/", userID] success:^(id obj){
        NSDictionary* result = obj;
        if ([[result objectForKey:@"status"] isEqualToString:@"OK"]) {
            //TODO maybe mapper should be used
            Photo* photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:_mainQueueContext];
            photo.url = result[@"large"];
            photo.pID = result[@"id"];
            photo.thumbnailURL = result[@"thumbnail"];
            photo.user = [UserService service].loggedInUser;
            [_mainQueueContext saveToPersistentStore:nil];
            [_delegate didUploadPhoto:photo image:image];
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
        DDLogError(@"failed to upload images");
        [_delegate didFailUploadPhoto:image];
    } progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
        _hud.progress = totalBytesLoaded * 1.0 / totalBytesExpected;
    }];
}

-(void)doChangeAvatar:(UIImage*)image withName:(NSString*)filename{
    NSString* userID = [[UserService service].loggedInUser.uID stringValue];
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%@/avatar/", userID]
                                     success:^(id obj) {
                                         DDLogVerbose(@"avatar updated");
                                         [_hud hide:YES];
                                         NSDictionary* data = obj;
                                         [_delegate didUploadAvatar:image withData:data];
                                         [_viewController dismissModalViewControllerAnimated:YES];
                                         NSString* big_avatar = data[@"big_avatar"];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:AVATAR_UPDATED_NOTIFICATION object:[URLService  absoluteURL:big_avatar]];
                                     } failure:^{
                                         DDLogError(@"failed to update avatar");
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
        }
        if (buttonIndex == 0) {
            _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else if(buttonIndex == 1){
            _pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }else if (buttonIndex == 2){
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
