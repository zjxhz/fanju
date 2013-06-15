//
//  SideMealCell.m
//  Fanju
//
//  Created by Xu Huanze on 3/25/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "SideMealCell.h"
#import "AKSegmentedControl.h"
#define CELL_HEIGHT 75
@implementation SideMealCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildUI];
    }
    return self;
}

-(void)buildUI{
    UIImage* currentMealsBg = [UIImage imageNamed:@"side_current_meals"];
    UIImage* myMealsBg = [UIImage imageNamed:@"side_my_meals"];
    UIImage* createMealBg = [UIImage imageNamed:@"side_create_meal"];
    _currentMealsButton = [self createSegmentButtonItemWithTitle:@"当前饭局" image:currentMealsBg push_image:currentMealsBg selector:nil];
    _myMealsButton = [self createSegmentButtonItemWithTitle:@"我的饭局" image:myMealsBg push_image:myMealsBg selector:nil];
    _createMealButton = [self createSegmentButtonItemWithTitle:@"发起饭局" image:createMealBg push_image:createMealBg selector:nil];
    AKSegmentedControl* seg = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 270, 75)];
    seg.segmentedControlMode = AKSegmentedControlModeSticky;
    [seg setButtonsArray:@[_currentMealsButton, _myMealsButton, _createMealButton]];
    [self.contentView addSubview:seg];
    
    
    UIImage* separatorImg = [UIImage imageNamed:@"side_separator"];
    UIImageView* separatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT - separatorImg.size.height, separatorImg.size.width, separatorImg.size.height)];
    separatorView.image = separatorImg;
    [self.contentView addSubview:separatorView];
}

-(UIButton*)createSegmentButtonItemWithTitle:(NSString*)title image:(UIImage*)image push_image:(UIImage*)pimage selector:(SEL)selector{
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 90, 75)];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button setTitleColor:RGBCOLOR(178, 178, 178) forState:UIControlStateNormal];
    [button setTitleShadowColor:RGBACOLOR(0, 0, 0, 0.4) forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0, -2);
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:pimage forState:UIControlStateSelected];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    // the space between the image and text
    CGFloat spacing = 2.0;
    CGSize imageSize = button.imageView.frame.size;
    CGSize titleSize = button.titleLabel.frame.size;
    
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    titleSize = button.titleLabel.frame.size;
    button.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    
    UIImage* bg = [UIImage imageNamed:@"side_button_bg"];
    UIImage* bg_push = [UIImage imageNamed:@"side_button_bg_push"];
    [button setBackgroundImage:bg forState:UIControlStateNormal];
    [button setBackgroundImage:bg_push forState:UIControlStateSelected];
    [button setBackgroundImage:bg_push forState:UIControlStateHighlighted];
    [button setBackgroundImage:bg_push forState:UIControlStateSelected | UIControlStateHighlighted];

    return button;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
