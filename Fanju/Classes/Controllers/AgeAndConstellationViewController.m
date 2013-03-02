//
//  AgeAndConstellationViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AgeAndConstellationViewController.h"
#import "DateUtil.h"
#import "UserProfile.h"

@interface AgeAndConstellationViewController (){
    NSDate* _birthday;
    UIDatePicker *_datePicker;
    UIViewController* _nextViewController;
}

@end

@implementation AgeAndConstellationViewController
@synthesize delegate = _delegate;
@synthesize user = _user;

-(id)initWithUser:(UserProfile*)user next:(UIViewController*)nextViewController{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _nextViewController = nextViewController;
        _user = user;
        _birthday = _user.birthday ? _user.birthday : [DateUtil dateFromShortString:@"1989-11-06"];
    }
    return self;
}

-(id)initWithBirthday:(NSDate*)birthday{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _birthday = birthday ? birthday : [DateUtil dateFromShortString:@"1989-11-06"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 200, 320, 280)];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.minimumDate = [DateUtil dateFromShortString:@"1912-01-01"];
    _datePicker.maximumDate = [DateUtil dateFromShortString:@"2007-12-31"];
    _datePicker.date = _birthday;
    [_datePicker addTarget:self action:@selector(dateUpdated:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_datePicker];
    self.title = @"出生日期";
    if (_nextViewController) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    }
}

-(void)save:(id)sender{
    [_delegate birthdayUpdate:_birthday];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)next:(id)sender{
    _user.birthday = _datePicker.date;
    [self.navigationController pushViewController:_nextViewController animated:YES];
}

-(void)dateUpdated:(id)sender{
    _birthday = _datePicker.date;
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }    
    
    NSInteger age =  [DateUtil ageFromBirthday:_birthday];
    NSString* constellation = [DateUtil constellationFromBirthday:_birthday];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"年龄";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d岁", age];
            break;
        case 1:
            cell.textLabel.text = @"星座";
            cell.detailTextLabel.text = constellation;
            break;
        default:
            break;
    }    
    
    return cell;
}
@end
