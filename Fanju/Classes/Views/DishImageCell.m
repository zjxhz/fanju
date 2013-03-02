//
//  DishImageCell.m
//  EasyOrder
//
//  Created by igneus on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DishImageCell.h"
#import <Three20/Three20.h>
#import "MyCustomStylesheet.h"
#import "OrderManager.h"

#define LEFT_GAP 5
#define HORIZON_GAP 10
#define IMG_WIDTH self.frame.size.width / 2
#define TOP_GAP 2
#define LABEL_HEIGHT 30
#define BUTTON_WIDTH 50
#define AMOUNT_WIDTH 15
#define NAME_RECT CGRectMake(LEFT_GAP + IMG_WIDTH + HORIZON_GAP, TOP_GAP, IMG_WIDTH, LABEL_HEIGHT)
#define PRICE_RECT CGRectMake(LEFT_GAP + IMG_WIDTH + HORIZON_GAP, TOP_GAP + NAME_RECT.origin.y + NAME_RECT.size.height, IMG_WIDTH, LABEL_HEIGHT)
#define PLUS_RECT CGRectMake(LEFT_GAP + IMG_WIDTH + HORIZON_GAP, TOP_GAP + PRICE_RECT.origin.y + PRICE_RECT.size.height, BUTTON_WIDTH, LABEL_HEIGHT)
#define AMOUNT_RECT CGRectMake(LEFT_GAP + PLUS_RECT.origin.x + PLUS_RECT.size.width, PLUS_RECT.origin.y, AMOUNT_WIDTH, LABEL_HEIGHT)
#define MINUS_RECT CGRectMake(LEFT_GAP + AMOUNT_RECT.origin.x + AMOUNT_RECT.size.width, PLUS_RECT.origin.y, BUTTON_WIDTH, LABEL_HEIGHT)

#define LABEL_WIDTH 90
#define ONE_ROW_TOP_GAP 10
#define NAME_ONE_ROW_RECT CGRectMake(LEFT_GAP, ONE_ROW_TOP_GAP, LABEL_WIDTH, LABEL_HEIGHT)
#define PRICE_ONE_ROW_RECT CGRectMake(LEFT_GAP + NAME_ONE_ROW_RECT.origin.x + NAME_ONE_ROW_RECT.size.width, ONE_ROW_TOP_GAP, LABEL_WIDTH, LABEL_HEIGHT)
#define PLUS_ONE_ROW_RECT CGRectMake(LEFT_GAP + PRICE_ONE_ROW_RECT.origin.x + PRICE_ONE_ROW_RECT.size.width, ONE_ROW_TOP_GAP, BUTTON_WIDTH, LABEL_HEIGHT)
#define AMOUNT_ONE_ROW_RECT CGRectMake(LEFT_GAP + PLUS_ONE_ROW_RECT.origin.x + PLUS_ONE_ROW_RECT.size.width, ONE_ROW_TOP_GAP, AMOUNT_WIDTH, LABEL_HEIGHT)
#define MINUS_ONE_ROW_RECT CGRectMake(LEFT_GAP + AMOUNT_ONE_ROW_RECT.origin.x + AMOUNT_ONE_ROW_RECT.size.width, ONE_ROW_TOP_GAP, BUTTON_WIDTH, LABEL_HEIGHT)

@interface DishImageCell()
@property (nonatomic, strong) TTImageView *image;
@property (nonatomic, strong) UILabel *name;
@property (nonatomic, strong) UILabel *price;
@property (nonatomic, strong) TTButton *plus;
@property (nonatomic, strong) TTButton *minus;
@property (nonatomic, strong) UILabel *amount;
@property (nonatomic, strong) UIImageView *tagImg;
@property (nonatomic) BOOL created;

- (void)addDish;
- (void)minusDish;
- (void)refreshDishStatus;
- (void)handleImgGesture:(UITapGestureRecognizer*)gesture;

@end

@implementation DishImageCell
@synthesize dish = _dish;
@synthesize image = _image;
@synthesize name = _name;
@synthesize price = _price;
@synthesize plus = _plus, minus = _minus, amount = _amount;
@synthesize tagImg = _tagImg;
@synthesize created = _created;
@synthesize displayMode = _displayMode;
@synthesize imageTappedAction = _imageTappedAction;

- (void)setDish:(Dish *)dish {
    _dish = dish;
    
    if (dish.pic && [dish.pic length] > 0 && self.displayMode == CellDisplayImageMode) {
        [self.image setUrlPath:dish.pic];
    } else {
        [self.image setUrlPath:nil];
    }
    
    [self.name setText:dish.name];
    [self.price setText:[NSString stringWithFormat:@"价格: %.2lf/份", [dish.price doubleValue]]];
    if ([dish.hasTags count] > 0) {
        [self.tagImg setImage:[UIImage imageNamed:@"thumbup.png"]];
        [self.tagImg setHidden:NO];
    } else {
        [self.tagImg setHidden:YES];
    }
    
    int numOfOrders = [[OrderManager sharedManager] numOfOrderItemWithDishID:dish.dishID];
    [self.amount setText:[NSString stringWithFormat:@"%d", numOfOrders]];
    
    if (numOfOrders > 0) {
        [self.minus setEnabled:YES];
    } else {
        [self.minus setEnabled:NO];
    }
}

- (void)setDisplayMode:(CellDisplayMode)displayMode {
    if (_displayMode != displayMode) {
        _displayMode = displayMode;
        
        if (_displayMode == CellDisplayImageMode) {
            [self setFrame:CGRectMake(0, 0, self.frame.size.width, 120)];
            [self.price setFont:[UIFont boldSystemFontOfSize:17]];
            [self.image setHidden:NO];
            [self.name setFrame:NAME_RECT];
            [self.price setFrame:PRICE_RECT];
            [self.plus setFrame:PLUS_RECT];
            [self.amount setFrame:AMOUNT_RECT];
            [self.minus setFrame:MINUS_RECT];
        } else {
            [self setFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
            [self.price setFont:[UIFont systemFontOfSize:14]];
            [self.image setHidden:YES];
            [self.name setFrame:NAME_ONE_ROW_RECT];
            [self.price setFrame:PRICE_ONE_ROW_RECT];
            [self.plus setFrame:PLUS_ONE_ROW_RECT];
            [self.amount setFrame:AMOUNT_ONE_ROW_RECT];
            [self.minus setFrame:MINUS_ONE_ROW_RECT];
        }
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {        
        if (!self.created) {            
            [self setFrame:CGRectMake(0, 0, self.frame.size.width, 120)];
            
            self.image = [[TTImageView alloc] initWithFrame:CGRectMake(5, 2, self.frame.size.width / 2, self.frame.size.height - 4)];
            self.image.style = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] 
                                                       next:
                                [TTSolidFillStyle styleWithColor:[UIColor whiteColor] 
                                                            next:[TTContentStyle styleWithNext:
                                                                  [TTInnerShadowStyle styleWithColor:RGBACOLOR(0,0,0,0.5) 
                                                                                                blur:6 
                                                                                              offset:CGSizeMake(5, 5) 
                                                                                                next:nil]]]];
            [self.image setBackgroundColor:[UIColor clearColor]];
            [self.image setDefaultImage:[UIImage imageNamed:@"loading.gif"]];
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImgGesture:)];
            [self.image addGestureRecognizer:tapGesture];
            [self addSubview:self.image];    
            
            self.tagImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.image.frame.size.width - 50, 0, 50, 50)];
            [self.image addSubview:self.tagImg];
            
            self.name = [[UILabel alloc] initWithFrame:NAME_RECT];
            [self.name setBackgroundColor:[UIColor clearColor]];
            [self.name setTextColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1]];
            [self.name setFont:[UIFont boldSystemFontOfSize:17]];
            [self addSubview:self.name];
            
            self.price = [[UILabel alloc] initWithFrame:PRICE_RECT];
            [self.price setBackgroundColor:[UIColor clearColor]];
            [self.price setTextColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.6]];
            [self.price setFont:[UIFont boldSystemFontOfSize:17]];
            [self addSubview:self.price];
            
            self.plus = [TTButton buttonWithStyle:@"embossedButton:" title:@"+1"];
            [self.plus setFrame:PLUS_RECT];
            [self.plus addTarget:self action:@selector(addDish) forControlEvents:UIControlEventTouchDown];
            [self addSubview:self.plus];
            
            self.amount = [[UILabel alloc] initWithFrame:AMOUNT_RECT];
            [self.amount setBackgroundColor:[UIColor clearColor]];
            [self.amount setTextColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.6]];
            [self.amount setFont:[UIFont boldSystemFontOfSize:17]];
            [self.amount setTextAlignment:UITextAlignmentCenter];
            [self addSubview:self.amount];
            
            self.minus = [TTButton buttonWithStyle:@"embossedButton:" title:@"-1"];
            [self.minus setFrame:MINUS_RECT];
            [self.minus addTarget:self action:@selector(minusDish) forControlEvents:UIControlEventTouchDown];
            [self addSubview:self.minus];
            
            self.created = YES;
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)addDish {
    [[OrderManager sharedManager] addOrder:self.dish];
    [self refreshDishStatus];
}

- (void)minusDish {
    [[OrderManager sharedManager] removeOrder:self.dish];
    [self refreshDishStatus];
}

- (void)refreshDishStatus {
    int numOfOrders = [[OrderManager sharedManager] numOfOrderItemWithDishID:self.dish.dishID];
    [self.amount setText:[NSString stringWithFormat:@"%d", numOfOrders]];
    
    if (numOfOrders > 0) {
        [self.minus setEnabled:YES];
    } else {
        [self.minus setEnabled:NO];
    }
}

- (void)handleImgGesture:(UITapGestureRecognizer*)gesture {
     if (gesture.state == UIGestureRecognizerStateEnded) {
         self.imageTappedAction();
     }
}

@end
