//
//  CellTextEditorViewController.h
//  EasyOrder
//
//  Created by 浣泽 徐 on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum{
    CellTextEditorStyleTextFiled,
    CellTextEditorStyleTextView,
} CellTextEditorStyle;

@protocol CellTextEditorDelegate <NSObject>
-(void)valueSaved:(NSString*)value;
@end

@interface CellTextEditorViewController : UIViewController
@property(nonatomic, weak) id<CellTextEditorDelegate> delegate;
-(id) initWithText:(NSString*)initialText placeHolder:(NSString*)placeHolder style:(CellTextEditorStyle)style;
@end
