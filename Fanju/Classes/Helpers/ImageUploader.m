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
#import "GKImagePicker.h"

#define LARGE_AVATAR_LENGTH 220
#define MAX_PHOTO_HEIGHT 960
#define MAX_PHOTO_WIDTH 640
#define MAX_BACKGROUND_WIDTH 640
@implementation ImageUploader{
    UIActionSheet* _imagePickerActions;
    MBProgressHUD* _hud;
    GKImagePicker *_customCropPicker;
    UIImagePickerController* _normalImagePickerController;
    UIViewController* _viewController;
    NSManagedObjectContext* _mainQueueContext;
}

-(id)initWithViewController:(UIViewController*)viewController delegate:(id<ImageUploaderDelegate>)delegate{
    self = [super init];
    _viewController = viewController;
    self.delegate = delegate;
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _mainQueueContext = store.mainQueueManagedObjectContext;
    _customCropPicker = [[GKImagePicker alloc] init];
    _customCropPicker.delegate = self;
    _normalImagePickerController = [[UIImagePickerController alloc] init];
    _normalImagePickerController.delegate = self;
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

-(void)uploadBackgroundImage{
    self.option = BACKGROUND;
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
    if (_option == AVATAR || _option == BACKGROUND) {
        cropRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
        cropRect = [image convertCropRect:cropRect];
        image = [image croppedImage:cropRect];
    }
    
    CGSize newSize = image.size;
    if (_option == AVATAR && image.size.width > LARGE_AVATAR_LENGTH){
        newSize = CGSizeMake(LARGE_AVATAR_LENGTH, LARGE_AVATAR_LENGTH);
    } else if(_option == BACKGROUND && image.size.width > MAX_BACKGROUND_WIDTH){
        newSize = CGSizeMake(MAX_BACKGROUND_WIDTH, MAX_BACKGROUND_WIDTH);
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
    NSString* filename  = [self filename];
    if (_option == AVATAR) {
        [self doChangeAvatar:image withName:filename];
    } else if(_option == BACKGROUND){
        [self doChangeBackground:image withName:filename];
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
            _hud.progress = 1;
            _hud.labelText = @"上传成功";
            [_delegate didUploadPhoto:photo image:image];
        }
        else {
            _hud.labelText = @"上传失败";
            [_delegate didFailUploadPhoto:image];
        }
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
    } failure:^{
        _hud.labelText = @"上传失败";
        DDLogError(@"failed to upload images");
        [_delegate didFailUploadPhoto:image];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
    } progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
        CGFloat progress = totalBytesLoaded * 1.0 / totalBytesExpected;
        if (progress > 0.85) { //hack as there is always a delay when upload goes to 100% but success block is not invoked
            progress = 0.85;
        }
        _hud.progress = progress;
    }];
}

-(void)delayedDismiss{
    [_hud hide:YES afterDelay:1];
    [_viewController dismissModalViewControllerAnimated:YES];
}

-(void)doChangeAvatar:(UIImage*)image withName:(NSString*)filename{
    NSString* userID = [[UserService service].loggedInUser.uID stringValue];
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%@/avatar/", userID]
                                     success:^(id obj) {
                                         DDLogVerbose(@"avatar updated");
                                         NSDictionary* data = obj;
                                         [_delegate didUploadAvatar:image withData:data];
                                         NSString* big_avatar = data[@"big_avatar"];
                                         [[NSNotificationCenter defaultCenter] postNotificationName:AVATAR_UPDATED_NOTIFICATION object:[URLService  absoluteURL:big_avatar]];
                                         _hud.progress = 1;
                                         _hud.labelText = @"上传成功";
                                         [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
                                     } failure:^{
                                         DDLogError(@"failed to update avatar");
                                         _hud.labelText = @"上传失败";
                                         [_delegate didFailUploadAvatar:image];
                                         [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
                                     }progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
                                         CGFloat progress = totalBytesLoaded * 1.0 / totalBytesExpected;
                                         if (progress > 0.85) { //hack as there is always a delay when upload goes to 100% but success block is not invoked
                                             progress = 0.85;
                                         }
                                         _hud.progress = progress;
                                     }];
}


-(void)doChangeBackground:(UIImage*)image withName:(NSString*)filename{
    User* user = [UserService service].loggedInUser;
    [[NetworkHandler getHandler] uploadImage:image withName:filename toURL:[NSString stringWithFormat:@"user/%@/background/", user.uID]
                                     success:^(id obj) {
                                         DDLogVerbose(@"background updated");
                                         NSDictionary* data = obj;
                                         user.backgroundImage  = [data objectForKey:@"background_image"];
                                         [_delegate didUploadBackground:image withData:data];
//                                         NSString* background = data[@"background_image"];
//                                         [[NSNotificationCenter defaultCenter] postNotificationName:AVATAR_UPDATED_NOTIFICATION object:[URLService  absoluteURL:big_avatar]];
                                         _hud.progress = 1;
                                         _hud.labelText = @"上传成功";
                                         [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
                                     } failure:^{
                                         DDLogError(@"failed to update background");
                                         _hud.labelText = @"上传失败";
                                         [_delegate didFailUploadBackground:image];
                                         [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(delayedDismiss) userInfo:nil repeats:NO];
                                     }progress:^(NSInteger totalBytesLoaded, NSInteger totalBytesExpected) {
                                         CGFloat progress = totalBytesLoaded * 1.0 / totalBytesExpected;
                                         if (progress > 0.85) { //hack as there is always a delay when upload goes to 100% but success block is not invoked
                                             progress = 0.85;
                                         }
                                         _hud.progress = progress;
                                     }];
}


#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(_imagePickerActions == actionSheet){
//        if (_option == BACKGROUND) {
//            _customCropPicker.cropSize = CGSizeMake(320, USER_BACKGROUND_IMAGE_HEIGHT);
//        } else
        if(_option == AVATAR || _option == BACKGROUND){
            _normalImagePickerController.allowsEditing = YES;
//            _customCropPicker.cropSize = CGSizeMake(320, 320);
        } else if(_option == PHOTO){
            _normalImagePickerController.allowsEditing = NO;
        }
        
//        UIImagePickerController* temp = _option == BACKGROUND ? _customCropPicker.imagePickerController : _normalImagePickerController;
        UIImagePickerController* temp = _normalImagePickerController;
        if (buttonIndex == 0) {
            temp.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else if(buttonIndex == 1){
            temp.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }else if (buttonIndex == 2){
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_viewController presentModalViewController:temp animated:YES];
        });
        
    }
}

#pragma mark GKImagePicker
- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    DDLogVerbose(@"picked image size: %@, ratio: %.2f ", NSStringFromCGSize(image.size), image.size.height / image.size.width);
    CGSize newSize = image.size;
    if(_option == BACKGROUND && image.size.width > 640){
        newSize = CGSizeMake(MAX_BACKGROUND_WIDTH, MAX_BACKGROUND_HEIGHT);
    } else {
        
    }
    if (!CGSizeEqualToSize(image.size, newSize)) {
        DDLogVerbose(@"scale image size from %@ to %@", NSStringFromCGSize(image.size), NSStringFromCGSize(newSize));
        image = [image imageScaledToSize:newSize];
        DDLogVerbose(@"scaled size: %@ ", NSStringFromCGSize(image.size));
    }
    
    
    _hud = [MBProgressHUD showHUDAddedTo:_customCropPicker.imagePickerController.view animated:YES];
	_hud.mode = MBProgressHUDModeAnnularDeterminate;
    if (_option == AVATAR) {
        [self doChangeAvatar:image withName:[self filename]];
    } else if(_option == BACKGROUND){
        [self doChangeBackground:image withName:[self filename]];
    } else {
        DDLogWarn(@"unknown option: %d", _option);
    }
}

-(NSString*)filename{
    NSString* prefix = @"a";
    if (_option == PHOTO) {
        prefix = @"p";
    } else if(_option == BACKGROUND){
        prefix = @"b";
    }
    NSString* userID = [[UserService service].loggedInUser.uID stringValue];
    return [NSString stringWithFormat:@"%@_%@_%.0f.jpg", userID, prefix, [[NSDate date] timeIntervalSince1970] * 1000 ];
}

@end
