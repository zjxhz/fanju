//
//  XMPPRecentContactCell.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 12/3/12.
//
//

#import "XMPPRecentContactCell.h"
#import "XMPPHandler.h"
#import "RecentContact.h"
#import "DateUtil.h"
#import "MKNumberBadgeView.h"

#define H_GAP 3
#define V_GAP 3
#define USER_IMAGE_SIDE_LENGTH 50
#define COMMENT_WIDTH (320-USER_IMAGE_SIDE_LENGTH - H_GAP*4)
#define LABEL_HEIGHT 18
#define SMALL_FONT_SIZE 12

@interface XMPPRecentContactCell () {
    UILabel* _timeLabel;
    MKNumberBadgeView* _numberBadge;
}
@end

@implementation XMPPRecentContactCell
@synthesize object = _object;

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)item {
    return 81;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)identifier {
    
	if (self = [super initWithStyle:UITableViewCellStyleSubtitle
                    reuseIdentifier:identifier]) {        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
        _timeLabel.textColor = [UIColor grayColor];
        self.accessoryView = _timeLabel;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _numberBadge = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(45, 0, 15, 15)];
	}
    
	return self;
}



#pragma mark -
#pragma mark TTTableViewCell

- (id)object {
    return _object;
}

- (void)setObject:(id)object {
    if (self.object != object) {
        [super setObject:object];
        _object = object;
        RecentContact *item = object;
        XMPPJID* contactJID = [XMPPJID jidWithString:item.contact];
        
        XMPPHandler* xmppHandler =[XMPPHandler sharedInstance];
        XMPPUserCoreDataStorageObject *user = [xmppHandler.xmppRosterStorage userForJID:contactJID
                                                                  xmppStream:xmppHandler.xmppStream
                                                        managedObjectContext:xmppHandler.rosterManagedObjectContext];


        self.detailTextLabel.text = item.message;
        _timeLabel.text = item.time ? [DateUtil userFriendlyStringFromDate:item.time] : @"";
        if (!user) {
            self.imageView.image = [UIImage imageNamed:@"anno"];
            self.textLabel.text = nil;
            self.detailTextLabel.text = nil;
            [_numberBadge removeFromSuperview];
        }
        
        if (user.photo) {
            self.imageView.image = user.photo;
        } else {
            NSData *photoData = [xmppHandler.xmppvCardAvatarModule photoDataForJID:user.jid];
            if (photoData){
                self.imageView.image = [UIImage imageWithData:photoData];
            }
            else {
                [xmppHandler.xmppvCardTempModule fetchvCardTempForJID:contactJID useCache:NO];
                self.imageView.image = [UIImage imageNamed:@"anno"];
            }
        }
        
        if (user.nickname) {
            self.textLabel.text = user.nickname;
        } else {
            [xmppHandler.xmppvCardTempModule fetchvCardTempForJID:contactJID useCache:NO];
            self.textLabel.text = @"";
        }
        
        NSInteger unreadCount = [item.unread integerValue];
        if (unreadCount> 0) {
            _numberBadge.value = unreadCount;
            [self.contentView addSubview:_numberBadge];
        } else {
            [_numberBadge removeFromSuperview];
        }

        

    }


}

@end
