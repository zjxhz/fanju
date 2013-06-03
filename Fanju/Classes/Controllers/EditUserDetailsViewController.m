//
//  EditUserDetailsViewController.m
//  Fanju
//
//  Created by Xu Huanze on 5/22/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "EditUserDetailsViewController.h"
#import "EditUserDetailsHeaderView.h"
#import "User.h"
#import "AvatarFactory.h"
#import "TextFormCell.h"
#import "DateUtil.h"
#import "WidgetFactory.h"
#import "TextViewCell.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "SVProgressHUD.h"
#import "NetworkHandler.h"
#import "UserTagsViewController.h"
#import "ImageUploader.h"


#define DATE_PICKER_HEIGHT 215
#define GenderPickerHeight 162.0

@implementation EditUserDetailsViewController{
    EditUserDetailsHeaderView* _headerView;
    NSString* _name;
    NSString* _motto;
    NSString* _college;
    NSString* _workFor;
    NSString* _occupation;
    NSDate* _birthday;
    DatePickerWithToolbarView* _datePicker;
    UIPickerView* _genderPicker;
    UITableView* _tableView;
    ImageUploader* _uploader;
    NSInteger _gender;
}

- (id)init{
    if (self = [super init]) {
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"编辑资料";
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"保存" target:self action:@selector(saveDetails:)];
//    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
//    reg.delegate = self;
//    [self.view addGestureRecognizer:reg];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.backgroundView = nil;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _tableView.frame = self.view.frame;
    [self createDatePicker];
    [self createGenderPicker];
}

-(UIView*)headerView{
    if (!_headerView) {
        UIViewController* temp = [[UIViewController alloc] initWithNibName:@"EditUserDetailsHeaderView" bundle:nil];
        _headerView = (EditUserDetailsHeaderView*)temp.view;
        _headerView.personalBgView.contentMode = UIViewContentModeScaleAspectFill;
        _headerView.personalBgView.clipsToBounds = YES;
        if (_user.backgroundImage) {
            [_headerView.personalBgView setPathToNetworkImage:[URLService absoluteURL:_user.backgroundImage] forDisplaySize:_headerView.personalBgView.frame.size contentMode:UIViewContentModeScaleAspectFill];
        } else {
            _headerView.personalBgView.image = [UIImage imageNamed:@"restaurant_sample.jpg"];
        }

        [_headerView.editPersonalBgButton addTarget:self action:@selector(editBackgroundImage:) forControlEvents:UIControlEventTouchUpInside];
        CGRect frame = CGRectMake(5, 105, 70, 70);
        NINetworkImageView* avatarView = [AvatarFactory avatarWithBg:_user big:YES];
        avatarView.frame = frame;
        [_headerView addSubview:avatarView];
    }
    
    return _headerView;
}

-(void)createDatePicker{
//    CGFloat y = self.view.frame.size.height - DATE_PICKER_HEIGHT;
//    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, y, 320, DATE_PICKER_HEIGHT)];
//    _datePicker.datePickerMode = UIDatePickerModeDate;
//    _datePicker.minimumDate = [DateUtil dateFromShortString:@"1913-01-01"];
//    _datePicker.maximumDate = [DateUtil dateFromShortString:@"2007-12-31"];
//    _datePicker.date = _birthday;
//    [_datePicker addTarget:self action:@selector(dateUpdated:) forControlEvents:UIControlEventValueChanged];
    CGFloat y = self.view.frame.size.height - DateTimePickerHeight;
    _datePicker = [[DatePickerWithToolbarView alloc] initWithFrame:CGRectMake(0, y, 320, DateTimePickerHeight)];
    _datePicker.datePickerDelegate = self;
    if (_birthday) {
        _datePicker.picker.date = _birthday;
    } else {
        _datePicker.picker.date = [DateUtil dateFromShortString:@"1991-02-27"];
    }
    [_datePicker setMode:UIDatePickerModeDate];
    [self.view addSubview:_datePicker];
    [_datePicker setHidden:YES animated:NO];
}

-(void)createGenderPicker{
    CGFloat y = self.view.frame.size.height - GenderPickerHeight - 20;
    _genderPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, y, 320, GenderPickerHeight)];
    _genderPicker.dataSource = self;
    _genderPicker.delegate = self;
    _genderPicker.hidden = YES;
    [self.view addSubview:_genderPicker];
}

-(void)datePicked:(NSDate *)date{
    _birthday = date;
    [_tableView reloadData];
    _tableView.userInteractionEnabled = YES;
}

-(void)datePickCanceled{
    _tableView.userInteractionEnabled = YES;
}
-(void)setUser:(User *)user{
    _user = user;
    _name = _user.name;
    _motto = _user.motto;
    _college = _user.college;
    _workFor = _user.workFor;
    _occupation = _user.occupation;
    _birthday = _user.birthday;
    _gender = [_user.gender integerValue];
    [_tableView reloadData];
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section > 0) {
        return nil;
    }
    return [self headerView];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 195;
    }
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){
        if(indexPath.row == 0) {
            CGSize textSize = [_motto sizeWithFont:[UIFont systemFontOfSize:15.0f] constrainedToSize:CGSizeMake(260, 400) lineBreakMode: UILineBreakModeWordWrap];
            return textSize.height + 40;
        } else if(indexPath.row == 1){
            return 68;
        }
    }
    return 45;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return 3;
    } else {
        return 5;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *TextFormCellIdentifier = @"TextFormCell";
    static NSString *CellIdentifier = @"Cell";
    static NSString *BirthdayCellIdentifier = @"BirthdayCell";
    static NSString *SubtitleCellIdentifier = @"SubtitleCell";
    
    UITableViewCell* cell = nil;
    if(indexPath.section == 0){
        if(indexPath.row == 0 ){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textLabel.text = @"名字";
            textFormCell.textField.font = [UIFont systemFontOfSize:15];
            textFormCell.textField.textColor = RGBCOLOR(0x50, 0x50, 0x50);
            textFormCell.textField.text = _name;
            textFormCell.textField.tag = 0;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"性别";
            cell.detailTextLabel.text = _gender ? @"女" : @"男";
        } else if(indexPath.row == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BirthdayCellIdentifier];
            cell.textLabel.text = @"生日";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [DateUtil longStringFromDate:_birthday];
        }
    } else if(indexPath.section == 1){
        if (indexPath.row == 0) {
            cell = [_tableView dequeueReusableCellWithIdentifier:SubtitleCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SubtitleCellIdentifier];
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.text = @"签名";
            cell.detailTextLabel.text = _motto;
        } else if(indexPath.row == 1){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"兴趣";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = [TagService textOfTags:[_user.tags allObjects]]; //TODO local copy
        } else if(indexPath.row == 2){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textLabel.text = @"学校";
            textFormCell.textField.font = [UIFont systemFontOfSize:15];
            textFormCell.textField.textColor = RGBCOLOR(0x50, 0x50, 0x50);
            textFormCell.textField.tag = 12;
            textFormCell.textField.text = _college;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 3){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textLabel.text = @"单位";
            textFormCell.textField.font = [UIFont systemFontOfSize:15];
            textFormCell.textField.textColor = RGBCOLOR(0x50, 0x50, 0x50);
            textFormCell.textField.tag = 13;
            textFormCell.textField.text = _workFor;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 4){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textField.font = [UIFont systemFontOfSize:15];
            textFormCell.textField.textColor = RGBCOLOR(0x50, 0x50, 0x50);
            textFormCell.textLabel.text = @"职业";
            textFormCell.textField.tag = 14;
            textFormCell.textField.text = _occupation;
            textFormCell.textField.delegate = self;
        }
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.textColor = RGBCOLOR(0x50, 0x50, 0x50);
    return cell;
}

-(void)saveDetails:(id)sender{
    [self.view findAndResignFirstResponder];
    [SVProgressHUD showWithStatus:@"正在保存…" maskType:SVProgressHUDMaskTypeBlack];
    NSMutableDictionary *dict = [@{@"name":_name, @"motto":_motto, @"occupation": _occupation,
                                 @"work_for":_workFor, @"college":_college, @"gender": [NSString stringWithFormat:@"%d", _gender]} mutableCopy];
    if (_birthday) {
        [dict setValue:[DateUtil longStringFromDate:_birthday] forKey:@"birthday"];
    }
    [[NetworkHandler getHandler] sendJSonRequest:[NSString stringWithFormat:@"%@://%@/api/v1/user/%@/", HTTPS, EOHOST, _user.uID]
                                          method:PATCH
                                      jsonObject:dict
                                         success:^(id obj) {
                                             [SVProgressHUD dismissWithSuccess:@"保存成功！"];
                                             DDLogInfo(@"user info updated");
                                             _user.name = _name;
                                             _user.motto = _motto;
                                             _user.occupation = _occupation;
                                             _user.workFor = _workFor;
                                             _user.college = _college;
                                             NSManagedObjectContext *context = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
                                             NSError* error;
                                             if(![context saveToPersistentStore:&error]){
                                                 DDLogError(@"failed to save updated user info");
                                             }
                                             
                                             [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_UPDATE object:_user];
                                             [self.navigationController popViewControllerAnimated:YES];
                                             
                                         } failure:^{
                                             [SVProgressHUD dismissWithSuccess:@"操作失败，请稍后再试"];
                                             DDLogError(@"faile to save user info");
                                         }];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            [self scrollToBottom];
            _tableView.userInteractionEnabled = NO;
            _genderPicker.hidden = NO;
//            <#statements#>
        } else if (indexPath.row == 2) {
            [_datePicker setHidden:NO animated:YES];
            
            [self scrollToBottom];
            _tableView.userInteractionEnabled = NO;
        } 
    }  else if(indexPath.section == 1){
        if (indexPath.row == 0) {
            SetMottoViewController* vc = [[SetMottoViewController alloc] init];
            [vc setMotto:_motto];
            vc.mottoDelegate = self;
            vc.navigationItem.leftBarButtonItem = [[WidgetFactory sharedFactory] backButtonWithTarget:vc action:@selector(saveMotto:)];
            [self.navigationController pushViewController:vc animated:YES];
        }else if (indexPath.row == 1) {
            UserTagsViewController *ut = [[UserTagsViewController alloc] initWithUser:_user];
            ut.tagDelegate = self;
            [self.navigationController pushViewController:ut animated:YES];
            
        }
    }
}

-(IBAction)editBackgroundImage:(id)sender{
    if (!_uploader) {
        _uploader = [[ImageUploader alloc] initWithViewController:self delegate:self];
    }
    [_uploader uploadBackgroundImage];
}
//-(void)viewTapped:(id)sender{
//    [self.view findAndResignFirstResponder];
//    [_picker setHidden:YES animated:YES];
//}


#pragma mark UIGestureRecognizerDelegate <NSObject>
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
//    if ([touch.view isKindOfClass:[UITextField class]]
//        || [touch.view isKindOfClass:[UITextView class]]
//            || [[touch.view superview] isKindOfClass:[UITableViewCell class]]
//        || [touch.view isKindOfClass:[UIButton class]]) {
//        return NO;
//    }
//    return YES;
//}

#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField{
    switch (textField.tag) {
        case 0:
            _name = textField.text;
            break;
        case 12:
            _college = textField.text;
            break;
        case 13:
            _workFor = textField.text;
            break;
        case 14:
            _occupation = textField.text;
            break;
        default:
            break;
    }
    CGRect frame = _tableView.frame;
    frame.origin.y = 0;
    [UIView animateWithDuration:0.5 animations:^{
        _tableView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    CGRect frame = _tableView.frame;
    if (textField.tag == 0) {
        frame.origin.y = -190;
    } else {
        frame.origin.y = -130 -(textField.tag - 12) * 45; //tags for the 2nd section start from 12
    }

    [UIView animateWithDuration:0.5 animations:^{
        _tableView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

#pragma mark UITextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView{
    _motto = textView.text;
    [_tableView reloadData];

    CGRect frame = _tableView.frame;
    frame.origin.y = 0;
    [UIView animateWithDuration:0.5 animations:^{
        _tableView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    CGRect frame = _tableView.frame;
    frame.origin.y = -55;
    _tableView.frame = frame;
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self scrollToBottom];
}

//so cells are visible when the keyboard pops up
-(void)scrollToBottom{
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark TagViewControllerDelegate
-(void)tagsSaved:(NSArray*)newTags forUser:(User*)user{
    [_tableView reloadData];
}

#pragma mark ImageUploaderDelegate
-(void)didUploadBackground:(UIImage*)image  withData:(NSDictionary*)data{
    _headerView.personalBgView.image = image;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_UPDATE object:_user];
}
-(void)didFailUploadBackground:(UIImage*)image{
    DDLogError(@"failed to upload background image");
}

#pragma mark UIPickerViewDataSource
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return 2;
}

#pragma mark UIPickerViewDelegate
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    return 320;
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 25;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return row == 0 ? @"男" : @"女";
}

//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view;

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    _gender = row;
    _genderPicker.hidden = YES;
    _tableView.userInteractionEnabled = YES;
    [_tableView reloadData];
}

#pragma mark SetMottoDelegate
-(void)mottoDidSet:(NSString *)motto{
    _motto = motto;
    [self.navigationController popViewControllerAnimated:YES];
    [_tableView reloadData];
}

@end
