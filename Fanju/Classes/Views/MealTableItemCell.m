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

#define MAX_VISIBLE_PARTICIPANTS 5
#define CELL_RECT CGRectMake(0, 0, 320, 340) 
@interface MealTableItemCell (){
    UIImageView* _backgroundView;
    NSDateFormatter *_dateFormatter;
}
@end

@implementation MealTableItemCell

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {  
	// Set the height for the particular cell
	return 340.0;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:style
                    reuseIdentifier:identifier]) {
        _backgroundView = [[UIImageView alloc] initWithFrame:CELL_RECT];
        self.backgroundView = _backgroundView;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"HH:mm - MM.dd"];
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
            UIColor* backgroundColor = RGBCOLOR(0xBB, 0xBB, 0xBB);
            [backgroundColor set];
            CGRect bigFrame = CGRectMake(28, 0, 264, 326);
            CGContextFillRect(context, bigFrame);
            
            [self drawInfoInContext:context];
            //participants BG
            UIColor* participantsFrameBgColor = RGBCOLOR(0x33, 0x33, 0x33);
            [participantsFrameBgColor set];
            CGContextFillRect(context, CGRectMake(32, 264, 256, 58));
            
            _backgroundView.image = UIGraphicsGetImageFromCurrentImageContext();
            [self mealInfo].fullPhoto = _backgroundView.image;
            UIGraphicsEndImageContext();
        }
	}
    
}

-(void)drawInfoInContext:(CGContextRef)context{
    MealTableItem* item = (MealTableItem*)_item;
    CGFloat offset = 0;
    
    //Avarage and cost
    UIColor* textBackgroundColor = RGBACOLOR(0, 0, 0, 0.5);
    [textBackgroundColor set];
    CGContextFillRect(context, CGRectMake(35 + offset, 5, 150, 20));
    UIColor *textColor = RGBCOLOR(255, 0xF0, 0);
    [textColor set];
    NSString* costAndNumOfParticipants = [NSString stringWithFormat:NSLocalizedString(@"AverageCost", nil), item.mealInfo.price, item.mealInfo.actualPersons, item.mealInfo.maxPersons];
    [costAndNumOfParticipants drawAtPoint:CGPointMake(37 + offset, 9) withFont:[UIFont boldSystemFontOfSize:12]];
    
    //like
    [textBackgroundColor set];
    CGContextFillRect(context, CGRectMake(35 + offset, 28, 50, 20));
    UIImage *likeImage = [UIImage imageNamed:@"like.png"];
    [likeImage drawInRect:CGRectMake(40 + offset, 30, 15, 14)];
    NSString* likeText =[NSString stringWithFormat:@"%d", item.mealInfo.likes.count];
    [textColor set];
    [likeText drawAtPoint:CGPointMake(65 + offset, 29) withFont:[UIFont boldSystemFontOfSize:12]];
    
    //topic
    [textBackgroundColor set];
    CGContextFillRect(context, CGRectMake(32 + offset, 211, 256, 25));
    [textColor set];
    NSString* topicText = item.mealInfo.topic;
    [topicText drawAtPoint:CGPointMake(37 + offset, 215) withFont:[UIFont boldSystemFontOfSize:15]];
    
    //time
    [textBackgroundColor set];
    CGContextFillRect(context, CGRectMake(32 + offset, 236, 256, 20));
    [textColor set];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm - MM.dd"];
    NSString* timeText = [NSString stringWithFormat:NSLocalizedString(@"Time", nil),[df stringFromDate:item.mealInfo.time]];
    [timeText drawAtPoint:CGPointMake(37 + offset, 240) withFont:[UIFont systemFontOfSize:12]];

}

-(void)setMealImage:(UIImage*)mealImage{
    [self mergeImageToBackgroundView:[self cropImage:mealImage] forRect:CGRectMake(32, 4, 256, 256) background:YES];
}

-(void)setAvatar:(UIImage*)image forUser:(UserProfile*)user{
    MealTableItem *item = (MealTableItem *)_item;
    int index = [item.mealInfo.participants indexOfObject:user]; //[[self mealInfo].host isEqual:user] ? 0 : 
    if (index >= MAX_VISIBLE_PARTICIPANTS){
        return;
    }
    CGRect rect = CGRectMake(40 + 50 * index, 272, 41, 41);
    [self mergeImageToBackgroundView:image forRect:rect background:NO];
}

-(void)mergeImageToBackgroundView:(UIImage*)image forRect:(CGRect)rect background:(BOOL)background{
    id currentMealInfo = [self mealInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bounds = self.backgroundView.bounds;
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if ([self mealInfo].fullPhoto) {
            [[self mealInfo].fullPhoto drawInRect:CELL_RECT];
        }
        
        [image drawInRect:rect];
        if (background) {
            [self drawInfoInContext:context];
        }
        
        [self mealInfo].fullPhoto = UIGraphicsGetImageFromCurrentImageContext();

        
        UIGraphicsEndImageContext();
        if ([self mealInfo] == currentMealInfo) { //same object means current cell has not been reused yet and still visible
            _backgroundView.image = [self mealInfo].fullPhoto;
        }
    });
}

-(UIImage*)cropImage:(UIImage*)image{
    if (image.size.width >= image.size.height) {
        return [image croppedImage:CGRectMake((image.size.width - image.size.height)/2, 0, image.size.height, image.size.height)];
    } else {
        return [image croppedImage:CGRectMake((image.size.height - image.size.width)/2, 0, image.size.width, image.size.width)];
    }
}

#define PROFILE_MEAL_CELL 1
-(void)drawRect:(CGRect)rect{
#if PROFILE_MEAL_CELL
     NSDate* startTime = [NSDate date];
#endif
    if ([self mealInfo].finishLoadingAllImages) {
        [[self mealInfo].fullPhoto drawAtPoint:CGPointMake(0, 0)];
#if PROFILE_MEAL_CELL
        NSLog(@"%.3f ms for drawing full photo of meal: %@", [[NSDate date] timeIntervalSinceDate:startTime] * 1000, [self mealInfo].topic);
#endif
    } else {
        [super drawRect:rect];
#if PROFILE_MEAL_CELL
        NSLog(@"%.3f ms for calling super drawRect of meal: %@", [[NSDate date] timeIntervalSinceDate:startTime] *1000, [self mealInfo].topic);
#endif
    }
}
@end
