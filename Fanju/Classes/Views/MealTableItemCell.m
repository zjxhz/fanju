//
//  MealTableItemCell.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MealTableItemCell.h"
#import "MealTableItem.h"
#import "MealInfo.h"
#import "RestaurantInfo.h"
#import "Const.h"
#import "LabelWithInsets.h"
#import "AvatarFactory.h"
#import "UIImage+Utilities.h"
#import "DateUtil.h"

#define MAX_VISIBLE_PARTICIPANTS 5
#define CELL_RECT CGRectMake(0, 0, 320, 329) 
@interface MealTableItemCell (){
    UIImageView* _backgroundView;
}
@end

@implementation MealTableItemCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	return 329;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:style
                    reuseIdentifier:identifier]) {
        _backgroundView = [[UIImageView alloc] initWithFrame:CELL_RECT];
        self.backgroundView = _backgroundView;
	}
    
	return self;
}

#pragma mark -
#pragma mark TTTableViewCell

- (id)object {
	return _item;  
}

-(MealInfo*)mealInfo{
    MealTableItem* item = (MealTableItem*)_item;
    return item.mealInfo;
}

-(void)prepareForReuse{
    MealTableItem *item = (MealTableItem *)_item;
    item.mealInfo.fullPhoto = _backgroundView.image;
    [super prepareForReuse];
}

- (void)setObject:(id)object {
	if (_item != object) {
        [super setObject:object];
        if (!object) {
            _backgroundView.image = nil;
            return;
        }
        
        if ([self mealInfo].fullPhoto) {
            _backgroundView.image = [self mealInfo].fullPhoto;
        } else {
            CGRect bounds = self.backgroundView.bounds;
            UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            //big frame BG
            UIImage* meal_bg = [UIImage imageNamed:@"shouye_fj"];
            [meal_bg drawAtPoint:CGPointMake(9, 3)];
            
            [self drawInfoInContext:context];
            _backgroundView.image = UIGraphicsGetImageFromCurrentImageContext();
            [self mealInfo].fullPhoto = _backgroundView.image;
            UIGraphicsEndImageContext();
        }
	}
    
}

-(void)drawInfoInContext:(CGContextRef)context{
    MealTableItem* item = (MealTableItem*)_item;
    MealInfo* meal = item.mealInfo;
    CGFloat offset = 0;
    
    //Avarage and cost
    UIImage* cost_bg = [UIImage imageNamed:@"jiage"];
    [cost_bg drawAtPoint:CGPointMake(29 + offset, 8)];
    
    UIColor *textColor = RGBCOLOR(230, 230, 230);
    [textColor set];
    NSString* costAndNumOfParticipants = [NSString stringWithFormat:NSLocalizedString(@"AverageCost", nil),
                                          meal.price, (meal.maxPersons-meal.actualPersons)];
    [costAndNumOfParticipants drawAtPoint:CGPointMake(40 + offset, 13) withFont:[UIFont systemFontOfSize:12]];
    
    //participants BG
    UIColor* participantsFrameBgColor = RGBACOLOR(0, 0, 0, 0.5);
    [participantsFrameBgColor set];
    CGContextFillRect(context, CGRectMake(16, 200, 290, 83));
    
    textColor = [UIColor whiteColor];
    [textColor set];
    UIImage* loc = [UIImage imageNamed:@"loc"];
    [loc drawAtPoint:CGPointMake(24, 208)];
    [meal.restaurant.name drawAtPoint:CGPointMake(loc.size.width + 24 + 2, 208) withFont:[UIFont systemFontOfSize:12]];
    

    UIImage *photo_bg = [UIImage imageNamed:@"p_photo_bg"];
    int max = meal.participants.count > 5 ? 5 : meal.participants.count;
    for (int i = 0; i < max; ++i) {
        int x = 24 + 55 * i;
        [photo_bg drawAtPoint:CGPointMake(x, 227)];
    }
    
    //topic
    textColor = RGBCOLOR(50, 50, 50);
    [textColor set];
    NSString* topicText = meal.topic;
    UIFont* topicFont = [UIFont systemFontOfSize:18];
    CGFloat topicWidth = [topicText sizeWithFont:topicFont].width;
    CGFloat topicX = (320 - topicWidth) / 2;
    [topicText drawAtPoint:CGPointMake(topicX, 287) withFont:[UIFont boldSystemFontOfSize:18]];
    
    //time
    textColor = RGBCOLOR(150, 150, 150);
    [textColor set];
    NSString* timeText = [meal timeText];
    [timeText drawAtPoint:CGPointMake(100, 308) withFont:[UIFont systemFontOfSize:10]];

}

-(void)setMealImage:(UIImage*)mealImage{
    [self mergeImageToBackgroundView:[self cropImage:mealImage] forRect:CGRectMake(16, 8, 290, 275) background:YES];
}

-(void)setAvatar:(UIImage*)image forUser:(UserProfile*)user{
    MealTableItem *item = (MealTableItem *)_item;
    int index = [item.mealInfo.participants indexOfObject:user];
    if (index >= MAX_VISIBLE_PARTICIPANTS){
        return;
    }
    CGRect rect = CGRectMake(27.5 + 55 * index, 230, 46, 46);
    [self mergeImageToBackgroundView:image forRect:rect background:NO];
}

-(void)mergeImageToBackgroundView:(UIImage*)image forRect:(CGRect)rect background:(BOOL)background{
    CGRect bounds = self.backgroundView.bounds;
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    [self.backgroundView.layer renderInContext:context];
    CGContextClipToRect(context, rect);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [image drawInRect:rect];
    if (background) {
        [self drawInfoInContext:context];
    }
    _backgroundView.image = UIGraphicsGetImageFromCurrentImageContext();

    
    UIGraphicsEndImageContext();
}

-(UIImage*)cropImage:(UIImage*)image{
    CGSize size = image.size;
    if (size.width >= size.height) {
        CGFloat expectedWidth  = size.height*290.0/275.0;
        CGFloat x = (size.width - expectedWidth) / 2;
        CGRect newRect = CGRectMake(x, 0, expectedWidth, size.height);
//        NSLog(@"cropped rect: %@", NSStringFromCGRect(newRect));
        UIImage* cropped =  [image croppedImage:newRect];
        return cropped;
//        return [cropped resizedImage:CGSizeMake(290, 275) imageOrientation:UIImageOrientationUp];
    } else {
        NSLog(@"unsupported image");
        return nil;
    }
}
@end
