//
//  IndustryAndOccupationViewController.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/15/13.
//
//

#import "IndustryAndOccupationViewController.h"
#import "TextFormCell.h"

@interface IndustryAndOccupationViewController (){
    TextFormCell* _textCell;
    NSString* _industry;
    NSString* _occupation;
}

@end

@implementation IndustryAndOccupationViewController

- (id)initWithIndustry:(NSString*)industry andOccupation:(NSString*)occupation{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _occupation = occupation;
        _industry = industry;
        self.title = @"职业信息";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(save:)];
        UIGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        reg.cancelsTouchesInView = NO;
        reg.delegate = self;
        [self.view addGestureRecognizer:reg];
    }
    return self;
}

-(void)save:(id)sender{
    if ([_textCell.textField isEditing]) {
        [_textCell.textField endEditing:YES];
    }
    [_delegate occupationUpdated:_occupation withIndustry:_industry];
    [self.navigationController popViewControllerAnimated:YES];
}

 -(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
     if (section == 0) {
         return nil;
     } else {
         return @"所属行业";
     }
 }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [UserProfile industries].count;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =  nil;
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"OccupationCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell =[[TextFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            _textCell = (TextFormCell*)cell;
            _textCell.textField.placeholder = @"您在从事什么职业";
            _textCell.textField.delegate = self;
        }
        
        _textCell.textField.text = _occupation;
    } else {
        static NSString *CellIdentifier = @"IndustryCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = [[UserProfile industries] objectAtIndex:indexPath.row];
        if ([cell.textLabel.text isEqualToString:_industry]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return;
    } else {
        _industry = [[UserProfile industries] objectAtIndex:indexPath.row];
        [self.tableView reloadData];
    }
}

-(void)viewTapped:(id)sender{
    if ([_textCell.textField isFirstResponder]) {
        [_textCell.textField resignFirstResponder];
    }
}

#pragma mark UIGestureRecognizerDelegate <NSObject>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UITextField class]]) {
        return NO;
    }
    return YES;
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField{
    _occupation = textField.text;
}

@end
