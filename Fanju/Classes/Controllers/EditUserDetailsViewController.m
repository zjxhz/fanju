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

#define DATE_PICKER_HEIGHT 215
@implementation EditUserDetailsViewController{
    EditUserDetailsHeaderView* _headerView;
    NSString* _name;
    NSString* _motto;
    NSString* _college;
    NSString* _workFor;
    NSString* _occupation;
    TextViewCell* _mottoCell;
    UIDatePicker* _datePicker;
    NSDate* _birthday;
}

- (id)initWithStyle:(UITableViewStyle)style{
    if (self = [super initWithStyle:style]) {
    }
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    self.tableView.backgroundView = nil;
//    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.title = @"编辑资料";
    self.navigationItem.rightBarButtonItem = [[WidgetFactory sharedFactory] normalBarButtonItemWithTitle:@"保存" target:self action:@selector(saveDetails:)];
    [self createHeaderView];
    [self createDatePicker];
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    [self.view addGestureRecognizer:reg];

}

-(void)createHeaderView{
    UIViewController* temp = [[UIViewController alloc] initWithNibName:@"EditUserDetailsHeaderView" bundle:nil];
    _headerView = (EditUserDetailsHeaderView*)temp.view;
    CGRect frame = _headerView.avatarView.frame;
    _headerView.avatarView = [AvatarFactory avatarWithBg:_user big:YES];
    _headerView.avatarView.frame = frame;
    [_headerView addSubview:_headerView.avatarView];
    _headerView.personalBgView.contentMode = UIViewContentModeScaleAspectFill;
    _headerView.personalBgView.clipsToBounds = YES;
    _headerView.personalBgView.image = [UIImage imageNamed:@"restaurant_sample.jpg"];
}

-(void)createDatePicker{
    CGFloat y = self.view.frame.size.height - DATE_PICKER_HEIGHT;
    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, y, 320, DATE_PICKER_HEIGHT)];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.minimumDate = [DateUtil dateFromShortString:@"1913-01-01"];
    _datePicker.maximumDate = [DateUtil dateFromShortString:@"2007-12-31"];
    _datePicker.date = _birthday;
    [_datePicker addTarget:self action:@selector(dateUpdated:) forControlEvents:UIControlEventValueChanged];
}

-(void)dateUpdated:(id)sender{
    _birthday = _datePicker.date;
    [self.tableView reloadData];
}

-(void)setUser:(User *)user{
    _user = user;
    _name = _user.name;
    _motto = _user.motto;
    _college = _user.college;
    _workFor = _user.workFor;
    _occupation = _user.occupation;
    _birthday = _user.birthday;
    [self.tableView reloadData];
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section > 0) {
        return nil;
    }
    return _headerView;
    
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
//            CGSize textSize = [_motto sizeWithFont:[UIFont systemFontOfSize:15.0f] constrainedToSize:CGSizeMake(280, 400) lineBreakMode: UILineBreakModeWordWrap];
//            return textSize.height + 40;
//            if (_mottoCell) {
//                return _mottoCell.preferredHeight;
//            }
            return 95;
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
            textFormCell.textField.text = _name;
            textFormCell.textField.tag = 0;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"性别";
            cell.detailTextLabel.text = [UserService genderTextForUser:_user];
        } else if(indexPath.row == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BirthdayCellIdentifier];
            cell.textLabel.text = @"生日";
            cell.detailTextLabel.text = [DateUtil longStringFromDate:_birthday];
        }
    } else if(indexPath.section == 1){
        if (indexPath.row == 0) {
            cell = [[TextViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SubtitleCellIdentifier];
            _mottoCell = (TextViewCell*)cell;
            _mottoCell.textLabel.text = @"签名";
            _mottoCell.textView.text = _motto;
            _mottoCell.textView.delegate = self;
        } else if(indexPath.row == 1){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"兴趣";
            cell.detailTextLabel.text = [TagService textOfTags:[_user.tags allObjects]]; //TODO local copy
        } else if(indexPath.row == 2){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textLabel.text = @"学校";
            textFormCell.textField.tag = 12;
            textFormCell.textField.text = _college;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 3){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
            textFormCell.textLabel.text = @"单位";
            textFormCell.textField.tag = 13;
            textFormCell.textField.text = _workFor;
            textFormCell.textField.delegate = self;
        } else if(indexPath.row == 4){
            cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:TextFormCellIdentifier];
            TextFormCell* textFormCell = (TextFormCell*)cell;
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
                                 @"work_for":_workFor, @"college":_college} mutableCopy];
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
        if (indexPath.row == 2) {
            if (_datePicker.superview) {
                [_datePicker removeFromSuperview];
            } else {
                _datePicker.date = _birthday;
                [self.navigationController.view addSubview:_datePicker];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//                [self.tableView setContentOffset:CGPointMake(0, UITableViewScrollPositionBottom) animated:YES];
            }
        } else {
            [_datePicker removeFromSuperview];
        }
    } else {
        [_datePicker removeFromSuperview];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_datePicker removeFromSuperview];
}

-(void)viewTapped:(id)sender{
    [self.view findAndResignFirstResponder];
    [_datePicker removeFromSuperview];
}


#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if ([touch.view isKindOfClass:[UITextField class]]
        || [touch.view isKindOfClass:[UITextView class]]
            || [[touch.view superview] isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    return YES;
}

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
//    NSIndexPath* p00 = [NSIndexPath indexPathForRow:0 inSection:0];
//    TextFormCell* cell00 = (TextFormCell*)[self.tableView cellForRowAtIndexPath:p00];
//    _name = cell00.textField.text;
//    
//    NSIndexPath* p10 = [NSIndexPath indexPathForRow:0 inSection:1];
//    TextFormCell* cell10 = (TextFormCell*)[self.tableView cellForRowAtIndexPath:p10];
//    _motto = cell10.textField.text;
//    
//    NSIndexPath* p12 = [NSIndexPath indexPathForRow:2 inSection:1];
//    TextFormCell* cell12 = (TextFormCell*)[self.tableView cellForRowAtIndexPath:p12];
//    _college = cell12.textField.text;
//    
//    NSIndexPath* p13 = [NSIndexPath indexPathForRow:3 inSection:1];
//    TextFormCell* cell13 = (TextFormCell*)[self.tableView cellForRowAtIndexPath:p13];
//    _workFor = cell13.textField.text;
//    
//    NSIndexPath* p14 = [NSIndexPath indexPathForRow:4 inSection:1];
//    TextFormCell* cell14 = (TextFormCell*)[self.tableView cellForRowAtIndexPath:p14];
//    _occupation = cell14.textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UITextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView{
    _motto = textView.text;
    [self.tableView reloadData];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    [_datePicker removeFromSuperview];
}
@end
