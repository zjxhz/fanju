//
//  NameAndGenderViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NameAndGenderViewController.h"
#import "TextFormCell.h"
#import "AgeAndConstellationViewController.h"
#import "SetAvatarViewController.h"

@interface NameAndGenderViewController (){
    UISegmentedControl* _gender;
    SetAvatarViewController *_avatarViewController;
    AgeAndConstellationViewController* _ageAndConstellation;
}

@end

@implementation NameAndGenderViewController
@synthesize user = _user;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.userInteractionEnabled = YES;
    UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    reg.delegate = self;
    [self.view addGestureRecognizer:reg];
    _gender = [[UISegmentedControl alloc] initWithItems:@[@"女生", @"男生"]];
    _gender.frame = CGRectMake(20, 120, 280, _gender.frame.size.height);
    [self.view addSubview:_gender];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleBordered target:self action:@selector(next:)];
    self.title = @"名字和性别";
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self updateExitingValues];
}

-(void)updateExitingValues{
    TextFormCell* cell = (TextFormCell* )[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (![_user.username isEqualToString:_user.name]) { //meaning user name is set so it's different than the user name
        cell.textField.text = _user.name;
    }
    
    if (_user.gender != -1) {
        _gender.selectedSegmentIndex = 1 - _user.gender;
    }	
}
-(NSString*) valueForCellAtRow:(NSInteger)row{
    TextFormCell* cell = (TextFormCell* )[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return cell.textField.text;
}

-(void) setUser:(UserProfile *)user{
    _user = user;
    [self updateExitingValues];
}

-(void)next:(id)sender{
    if ([self valueForCellAtRow:0].length == 0) {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"姓名" message:@"请输入您的姓名" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return;
    }
    if (_gender.selectedSegmentIndex == -1) {
        UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"性别" message:@"请选择性别" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [a show];
        return;
    }

    _user.name = [self valueForCellAtRow:0];
    _user.gender = 1 - _gender.selectedSegmentIndex;
    
    
    if (!_avatarViewController) {
         _avatarViewController = [[SetAvatarViewController alloc] initWithUser:_user];
    }
    
    if (!_ageAndConstellation) {
        _ageAndConstellation = [[AgeAndConstellationViewController alloc] initWithUser:_user next:_avatarViewController];
    }

    [self.navigationController pushViewController:_ageAndConstellation animated:YES];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
    return 1;
}

//-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
//    return @"饭聚推行从线上到线下、面对面地交友的社交理念，所以也希望大家在这里使用真实姓名";
//}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = [UIColor clearColor];
    UILabel* footer = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 40)];
    footer.text = @"饭聚推行从线上到线下、面对面地交友的社交理念，所以也希望大家在这里使用真实姓名";
    footer.font = [UIFont systemFontOfSize:12];
    footer.numberOfLines = 2;
    footer.backgroundColor = [UIColor clearColor];
    [view addSubview:footer];
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TextFormCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"名字";
        cell.textField.placeholder = @"建议输入真实姓名";
    }    
    
    return cell;
}

-(void)viewTapped:(id)sender{
    TextFormCell *cell = (TextFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([cell.textField isFirstResponder]) {
        [cell.textField resignFirstResponder];
    }
}

#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UISegmentedControl class]] || [touch.view isKindOfClass:[UITextField class]]) {
        return NO;
    }
    return YES;
}
@end
