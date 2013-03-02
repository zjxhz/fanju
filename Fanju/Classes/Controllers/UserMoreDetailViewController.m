//
//  UserMoreDetailViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserMoreDetailViewController.h"
#import "DateUtil.h"
#import "DistanceUtil.h"
#import "Authentication.h"
#import "NetworkHandler.h"
#import "DictHelper.h"
#import "SVProgressHUD.h"
#import "AgeAndConstellationViewController.h"
#import "AvatarFactory.h"
#import "UIImage+Utilities.h"
#import "NewTagViewController.h"

@interface UserMoreDetailViewController (){
    NSArray *_sectionItems;
    BOOL _editingMode;
#warning remove _editable as this view is always editable
    BOOL _editable;
    NSDate* _birthday; //birthday is saved separately as it can not simply saved as section data
    UserImageView *_avatarView;
    UIImage* _uploadedImage;
    NSString* _industry;
    NSString* _occupation;
}

@end

@implementation UserMoreDetailViewController
@synthesize profile = _profile;

- (id)initWithStyle:(UITableViewStyle)style editable:(BOOL)editable
{
    self = [super initWithStyle:style];
    if (self) {
        _editingMode = YES;
        _editable = editable;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    return [self initWithStyle:style editable:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_editable) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(editOrSave:)];
    }
    self.tableView.delegate = self;
}

-(void)editOrSave:(id)sender{
    if (!_editingMode) {
        _editingMode = YES;
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItem.title = @"保存";
    } else {
        [self save];
    }
}

-(NSString*) cellValueAtSection:(NSInteger)section andRow:(NSInteger)row{
    NSArray *sectionArray = [_sectionItems objectAtIndex:section];
    NSArray *rowArray = [sectionArray objectAtIndex:row];
    return [rowArray objectAtIndex:1];
}
    

-(void)save{
    [SVProgressHUD showWithStatus:@"保存中…"];
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];           
    NSString* name = [self cellValueAtSection:0 andRow:0];
    NSString* motto = [self cellValueAtSection:0 andRow:1];
    NSInteger industryIntegerValue = [UserProfile industryValue:_industry];
    id industryValue = industryIntegerValue == [UserProfile industries].count - 1 ? [NSNull null] : [NSNumber numberWithInteger:industryIntegerValue];
    NSString* occupation = [[[self cellValueAtSection:4 andRow:1] componentsSeparatedByString:@"\n"] objectAtIndex:1];
    NSString* work_for = [self cellValueAtSection:4 andRow:2];
    NSString* college = [self cellValueAtSection:4 andRow:3];
    NSMutableDictionary *dict = [@{@"name":name, @"motto":motto, @"industry":industryValue, @"occupation": occupation,
                            @"work_for":work_for, @"college":college} mutableCopy];
    if (_birthday) {
        [dict setValue:[DateUtil longStringFromDate:_birthday] forKey:@"birthday"];
    }
    [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/", HTTPS, EOHOST, currentUser.uID]
                                         method:PATCH
                                      jsonObject:dict
                                        success:^(id obj) {
                                            [SVProgressHUD showSuccessWithStatus:@"保存成功！"];
                                            [[Authentication sharedInstance] refreshUserInfo:^(id obj){
                                                NSLog(@"user info refreshed");
                                                [self.delegate userProfileUpdated:obj];
                                            }failure:^(void){
                                                NSLog(@"user info refresh failed");
                                            }];
                                            
                                        } failure:^{
                                             [SVProgressHUD showSuccessWithStatus:@"保存失败，请稍后再试…"];
                                        }];
}

-(void)setProfile:(UserProfile *)profile{
    _profile = profile;
    _birthday = profile.birthday;
    NSArray *sectionItems0 = [NSArray arrayWithObjects:
                              [NSMutableArray arrayWithObjects:@"名字", _profile.name, nil],
                              [NSMutableArray arrayWithObjects:@"个人签名", _profile.motto, nil], nil];
    
    NSString* updated = @"未知时间";
    if (_profile.locationUpdatedTime) {
        NSTimeInterval interval = [_profile.locationUpdatedTime timeIntervalSinceNow] > 0 ? 0 : -[_profile.locationUpdatedTime timeIntervalSinceNow];
        updated = [DateUtil humanReadableIntervals: interval];
    }
    NSString *distance = [NSString stringWithFormat:@"%@ | %@", [DistanceUtil distanceToMe:_profile], updated];
    
    NSString *relation = nil;
    UserProfile *me = [[Authentication sharedInstance] currentUser];
    if([me isEqual:_profile]){
        relation = @"自己";
    } else if ([me isFollowing:_profile]) {
        relation = @"关注";
    } else {
        relation = @"陌生人";
    }
    
    NSArray *sectionItems1 = [NSArray arrayWithObjects:
                              [NSMutableArray arrayWithObjects:@"位置信息", distance, nil],
                              [NSMutableArray arrayWithObjects:@"关系", relation, nil], nil];
    
    NSArray *sectionItems2 = [NSArray arrayWithObjects:
                              [NSMutableArray arrayWithObjects:@"性别", @"      ", nil],//quick and dirty fix, spaces to make sure there is room for the gender icon 
                              [NSMutableArray arrayWithObjects:@"年龄", [NSString stringWithFormat:@"%d", [_profile age]], nil], 
                              [NSMutableArray arrayWithObjects:@"星座", [_profile constellation], nil],//todo how to calculate? 
                              [NSMutableArray arrayWithObjects:@"注册日期",  [DateUtil longStringFromDate:_profile.dateJoined], nil], nil];
    NSArray *sectionItems3 = [NSArray arrayWithObjects:
                              [NSMutableArray arrayWithObjects:@"新浪微博", _profile.weiboID ? @"已绑定" : @"未绑定", nil],nil];
   
    _industry = _profile.industry;
    _occupation = _profile.occupation;
    NSArray *sectionItems4 = @[
                              [@[@"爱好和特点", [_profile tagsToString]] mutableCopy],
                              [@[@"职业",  [NSString stringWithFormat:@"%@\n%@",_industry, _occupation]] mutableCopy],
                              [@[@"公司", _profile.workFor ? _profile.workFor : @""] mutableCopy],
                              [@[@"学校", _profile.college ? _profile.college : @""] mutableCopy]];
    
    _sectionItems = [NSArray arrayWithObjects:
                             sectionItems0, //placeholder for section 0 
                             sectionItems1, 
                             sectionItems2, 
                             sectionItems3, 
                             sectionItems4, nil];
    

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL) isCellEditableAtIndexPath:(NSIndexPath*)indexPath{
    switch (indexPath.section) {
        case 0:
        case 3:
        case 4:
            return YES;
        case 2:
            return indexPath.row == 1 || indexPath.row == 2;
        default:
            return NO;
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sectionItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sectionItems = [_sectionItems objectAtIndex:section];
    return sectionItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 1) {
                return 50;
            }
        case 4:
            if(indexPath.row == 1){
                return 75;
            }
        default:
            return 30;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   
    static NSString *CellIdentifier = @"Cell";

    UITableViewCellStyle style = UITableViewCellStyleValue1;
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:0]] || [indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:4]] ) {
        style = UITableViewCellStyleSubtitle;
    }
    

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
   
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:4]]) {
        cell.detailTextLabel.numberOfLines = 2;
    } else {
        cell.detailTextLabel.numberOfLines = 1;
    }
    
    NSArray *items = [_sectionItems objectAtIndex:indexPath.section];
    NSArray *row  = [items objectAtIndex:indexPath.row];

    cell.textLabel.text = [row objectAtIndex:0];
    cell.detailTextLabel.text = [row objectAtIndex:1];
    if (indexPath.section == 2 && indexPath.row == 0) {
        UIImageView *icon = [[UIImageView alloc] initWithImage:_profile.genderImage];
        icon.frame = CGRectMake(5, 5, icon.frame.size.width, icon.frame.size.height);
        [cell.detailTextLabel addSubview:icon];
    } else if (indexPath.section == 4 ){
        if (indexPath.row == 0) {
            cell.detailTextLabel.text = [_profile tagsToString];
        }
    }
    if ([self isCellEditableAtIndexPath:indexPath] && _editingMode) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 2:
            return @"基本信息";
        case 3:
            return @"社交网络";
        case 4:
            return @"个人介绍";
        default:
            break;
    }
    return nil;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    AgeAndConstellationViewController *aac;
    NewTagViewController* tagC;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CellTextEditorViewController* cellTextEditor;;
    if ([self isCellEditableAtIndexPath:indexPath] && _editingMode) {
        if (indexPath.section == 2) {
            aac = [[AgeAndConstellationViewController alloc] initWithBirthday:_profile.birthday];
            aac.delegate = self;
            [self.navigationController pushViewController:aac animated:YES];
        } else if (indexPath.section == 4 && indexPath.row == 0){
            tagC = [[NewTagViewController alloc] initWithStyle:UITableViewStyleGrouped];
            tagC.user = self.profile;
            tagC.delegate = self;
            tagC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissTagViewController:)];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tagC];
            [self presentModalViewController:navigationController animated:YES];
        } else if (indexPath.section == 4 && indexPath.row == 1){
            IndustryAndOccupationViewController* iovc = [[IndustryAndOccupationViewController alloc] initWithIndustry:_industry andOccupation:_occupation];
            iovc.delegate = self;
            [self.navigationController pushViewController:iovc animated:YES];
        } else {
            cellTextEditor= [[CellTextEditorViewController alloc] initWithText:cell.detailTextLabel.text placeHolder:nil style:CellTextEditorStyleTextFiled];
            cellTextEditor.delegate = self;
            [self.navigationController pushViewController:cellTextEditor animated:YES];
        }
    }
}
-(void)dismissTagViewController:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if ([self tableView:tableView titleForHeaderInSection:section] != nil){
        return 35;
    } else {
        return 0;
    }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone;
}

#pragma mark CellTextEditorDelegate
-(void)valueSaved:(NSString *)value{
    NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
    NSArray *section = [_sectionItems objectAtIndex:indexPath.section];
    NSMutableArray *row = [section objectAtIndex:indexPath.row];
    [row replaceObjectAtIndex:1 withObject:value];
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadData];
}

#pragma mark AgeAndConstellationDelegate
-(void)birthdayUpdate:(NSDate *	)birthday{
    //TODO hard coded age and constellation index
    NSArray *section = [_sectionItems objectAtIndex:2];
    NSMutableArray *row1 = [section objectAtIndex:1];
    [row1 replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%d",[DateUtil ageFromBirthday:birthday]]];
    NSMutableArray *row2 = [section objectAtIndex:2];
    [row2 replaceObjectAtIndex:1 withObject:[DateUtil constellationFromBirthday:birthday]];
    //    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    _birthday = birthday;
    [self.tableView reloadData];
    
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    CGRect cropRect = [[info valueForKey:UIImagePickerControllerCropRect] CGRectValue];
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];    
    UIImage *croppedImage = [originalImage croppedImage:cropRect];
    UIImage *resizedImage = [croppedImage resizedImage:CGSizeMake(640, 640) imageOrientation:originalImage.imageOrientation];

    NSLog(@"cropped rect: %@", NSStringFromCGRect(cropRect));
    NSLog(@"original image size: %@", NSStringFromCGSize(originalImage.size));
    NSLog(@"cropped image size: %@", NSStringFromCGSize(croppedImage.size));
    NSLog(@"resized image size: %@", NSStringFromCGSize(resizedImage.size));
    
    [self changeAvatarWithImage:resizedImage];
    
}

-(void)changeAvatarWithImage:(UIImage*)image{
    UserProfile* currentUser = [[Authentication sharedInstance] currentUser];       
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[currentUser avatarDictForUploading:image], @"avatar", nil];
    [SVProgressHUD showWithStatus:@"上传中…"];
    [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%d/", HTTPS, EOHOST, currentUser.uID]
                                          method:PATCH
                                      jsonObject:dict
                                         success:^(id obj) {
                                             [[Authentication sharedInstance] refreshUserInfo:^(id obj){
                                                 _profile = [[Authentication sharedInstance] currentUser];
                                                 _uploadedImage = image;
                                                 [SVProgressHUD showSuccessWithStatus:@"上传成功"];
                                                 [self.tableView reloadData];
//                                                 dispatch_async(dispatch_get_main_queue(), ^{                                                     _avatarView.defaultImage = image;            
//                                                 });
                                                 
                                                 [self dismissModalViewControllerAnimated:YES];
                                             } failure:^{
                                                 [SVProgressHUD showSuccessWithStatus:@"图片上传失败…"];
                                                 [self dismissModalViewControllerAnimated:YES];
                                             }];
                                         } failure:^{
                                             [SVProgressHUD showSuccessWithStatus:@"图片上传失败…"];
                                             [self dismissModalViewControllerAnimated:YES];
                                         }];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark TagViewControllerDelegate
-(void)tagsSaved:(NSArray*)newTags forUser:(UserProfile*)user{
    [self.tableView reloadData];
    [self.navigationController dismissModalViewControllerAnimated:YES];
    [self.delegate userProfileUpdated:_profile];
}

#pragma mark IndustryAndOccupationViewControllerDelegate
-(void)occupationUpdated:(NSString*)occupation withIndustry:(NSString*)industry{
    NSArray *section = [_sectionItems objectAtIndex:4];
    NSMutableArray *row = [section objectAtIndex:1];
    _industry = industry;
    _occupation = occupation;
    [row replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%@\n%@", industry, occupation]];
    [self.tableView reloadData];
}
@end
