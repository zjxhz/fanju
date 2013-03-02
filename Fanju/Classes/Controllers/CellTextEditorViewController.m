//
//  CellTextEditorViewController.m
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CellTextEditorViewController.h"
@interface CellTextEditorViewController (){
    NSString* _placeHolder;
    NSString* _initialText;
    CellTextEditorStyle _style;
    UITextField* _textField;
}

@end

@implementation CellTextEditorViewController
@synthesize delegate = _delegate;

-(id) initWithText:(NSString*)initialText placeHolder:(NSString*)placeHolder style:(CellTextEditorStyle)style{
    if (self = [super init]) {
        _initialText = initialText;
        _placeHolder = placeHolder;
        _style = style;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 300, 25)];
    _textField.placeholder = _placeHolder;
    _textField.text = _initialText;
    _textField.borderStyle = UITextBorderStyleRoundedRect;    
	[self.view addSubview:_textField];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
}

-(void)save:(id)sender{
    [_delegate valueSaved:_textField.text];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
