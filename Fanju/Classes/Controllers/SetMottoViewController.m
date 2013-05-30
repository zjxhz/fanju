//
//  SetMottoViewController.m
//  Fanju
//
//  Created by Xu Huanze on 5/30/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SetMottoViewController.h"
#import "WidgetFactory.h"
#import "NetworkHandler.h"
#import "Const.h"

@interface SetMottoViewController (){
    UITextView* _textView;
    NSString* _initialMotto;
//    UIView* _keyboardAccessoryView;
}

@end

@implementation SetMottoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)];
    _textView.contentInset = UIEdgeInsetsMake(3, 3, 3, 3);
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]];
    _textView.delegate = self;
    _textView.text = _initialMotto;
//    _keyboardAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
//    _keyboardAccessoryView.backgroundColor = [UIColor grayColor];
//    UILabel* wordCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 60, 20)];
//    wordCountLabel.textAlignment = UITextAlignmentCenter;
    
//    _textView.inputAccessoryView = [self input]
    [self.view addSubview:_textView];
    self.navigationItem.titleView = [[WidgetFactory sharedFactory] titleViewWithTitle:@"修改签名"];
    [_textView becomeFirstResponder];
}

-(void)setMotto:(NSString*)motto{
    _initialMotto = motto;
}

-(void)saveMotto:(id)sender{
    [_textView resignFirstResponder];
    [_mottoDelegate mottoDidSet:_textView.text];
}
#pragma mark UITextViewDelegate
//- (BOOL)textViewShouldBeginEditing:(UITextView *)textView;
//- (BOOL)textViewShouldEndEditing:(UITextView *)textView;
//
//- (void)textViewDidBeginEditing:(UITextView *)textView;
//- (void)textViewDidEndEditing:(UITextView *)textView;
//
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
//- (void)textViewDidChange:(UITextView *)textView;
//
//- (void)textViewDidChangeSelection:(UITextView *)textView;
@end
