//
//  SetAvatarViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SetAvatarViewController.h"
#import "UIImage+Utilities.h"
//#import "TagViewController.h"
#import "AvatarFactory.h"
#import "SVProgressHUD.h"

@interface SetAvatarViewController (){
    UIImageView* _photoView;
    UILabel* _intro;
    UIImageView* _cameraView;
//    TagViewController *_tagViewController;
    UserImageView* _userImageView;
    UITapGestureRecognizer *_tapGestureRecognizer;
    BOOL _avatarUpdated;
}

@end

@implementation SetAvatarViewController
@synthesize user = _user;

-(id)initWithUser:(UserProfile*)user{
    if (self = [super init]) {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"设置头像"];
    self.view.backgroundColor =[UIColor whiteColor];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraTapped:)];
    
    CGRect photoFrame =  CGRectMake(0, 50, 320, 320);
    
    _photoView = [[UIImageView alloc] initWithFrame:photoFrame];
    _photoView.hidden = YES;
    [self.view addSubview:_photoView];
    
	_cameraView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera"]];
    _cameraView.frame = CGRectMake((self.view.bounds.size.width - _cameraView.frame.size.width)/2, 120, _cameraView.frame.size.width, _cameraView.frame.size.height);
    [_cameraView setUserInteractionEnabled:YES];
    
    [_cameraView addGestureRecognizer:_tapGestureRecognizer];
    [self.view addSubview:_cameraView];

    CGRect introFrame = CGRectMake(10, 350, 300, 40);
    NSString* introText = @"请上传你在饭聚中的头像，90%的用户倾向于和有头像的用户聊天吃饭";
    if (_user.avatarURL) {
        _userImageView = [AvatarFactory avatarForUser:_user frame:photoFrame delegate:self];
        _photoView.image = _userImageView.image;//so that we know user has image set already
        [self.view addSubview:_userImageView];
        introFrame = CGRectMake(10, 380, 300, 40);
        introText = @"点击图片更改当前头像";
    }
    
    _intro = [[UILabel alloc] initWithFrame:introFrame];
    _intro.numberOfLines = 0;
    _intro.lineBreakMode = UILineBreakModeWordWrap;
    _intro.font = [UIFont systemFontOfSize:12];
    _intro.text = introText;
    [self.view addSubview:_intro];
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissmodalViewController:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleBordered target:self action:@selector(saveAvatar:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    }
}


-(void)saveAvatar:(id)sender{
    if (!_avatarUpdated) {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }
    [SVProgressHUD showWithStatus:@"正在上传……" maskType:SVProgressHUDMaskTypeBlack];
    _user.avatar = _photoView.image;
    assert(0);//not implemented
}


-(void)dismissmodalViewController:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)next:(id)sender{
    if (!_photoView.image) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"未选择头像" message:@"请选择头像" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return;        
    }
    _user.avatar = _photoView.image;
//    if (!_tagViewController) {
//        _tagViewController = [[TagViewController alloc] initWithUser:_user];
//        _tagViewController.isWithinWizard = YES;
//    }
//    [self.navigationController pushViewController:_tagViewController animated:YES];    
}

-(void)cameraTapped:(id)sender{
    [self showImagePicker];
}

-(void)showImagePicker{
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = YES;
    [self presentModalViewController:pickerController animated:YES];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    _avatarUpdated = YES;
    _userImageView.hidden = YES;
    _intro.hidden = YES;
    _cameraView.hidden = YES;
    
    CGRect cropRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    cropRect = [originalImage convertCropRect:cropRect];
    UIImage *croppedImage = [originalImage croppedImage:cropRect];
    UIImage *resizedImage = [croppedImage resizedImage:CGSizeMake(640, 640) imageOrientation:originalImage.imageOrientation];
    DDLogVerbose(@"Cropping: %@ -> %@ -> %@", NSStringFromCGSize(originalImage.size), NSStringFromCGSize(croppedImage.size), NSStringFromCGSize(resizedImage.size));

    [self.view sendSubviewToBack:_photoView];
    _photoView.image = resizedImage;
    _photoView.hidden = NO;
    _photoView.userInteractionEnabled = YES;
    [_photoView addGestureRecognizer:_tapGestureRecognizer];

    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma  mark UserImageDelegate
-(void)userImageTapped:(UserProfile*)user{
    [self showImagePicker];
}
@end
