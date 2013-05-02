//
//  ImageDownloader.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 10/27/12.
//
//

#import "ImageDownloader.h"
//@interface RequestDelegate : NSObject <TTURLRequestDelegate>
//@end
//
//@implementation RequestDelegate
//
//-(id) initWith
//
//@end

@implementation ImageDownloader

-(void)startDownload{
    [self download:[self.meal photoFullUrl]];
    //participant img will be downloaded later when meal is firstly downloaded, this is for the sake of drawing priority
}

-(void)download:(NSString*)url{
    TTURLRequest* request = [TTURLRequest requestWithURL:url delegate:self];
    request.response = [[TTURLImageResponse alloc] init];
    [request send];
}

#pragma mark TTURLRequestDelegate
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    NSString* url = request.urlPath;
    TTURLImageResponse* response = request.response;
    if ([url isEqualToString:[self.meal photoFullUrl]]) {
        [self.delegate mealImageDidLoad:self.indexPathInTableView withImage:response.image];
        [self startDownloadAvatars];
    }  else {
        for (UserProfile* user in self.meal.participants) {
            if ([url isEqualToString:[user avatarFullUrl]]){
                [self.delegate userSmallAvatarDidLoad:self.indexPathInTableView withImage:response.image forUser:user];
            }
        }
    }
    _finishedCounts++;
    [self checkIfFinish];
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error{
    NSString* url = request.urlPath;
    TTURLImageResponse* response = request.response;
    if ([url isEqualToString:[self.meal photoFullUrl]]) {
        [self.delegate mealImageDidLoad:self.indexPathInTableView withImage:response.image];
    } else {
        for (UserProfile* user in self.meal.participants) {
            if ([url isEqualToString:[user avatarFullUrl]]){
                [self.delegate userSmallAvatarDidLoad:self.indexPathInTableView withImage:response.image forUser:user];
            }
        }
    }
    
    _finishedCounts++;
    [self checkIfFinish];
}

-(void)startDownloadAvatars{
    for (UserProfile* user in self.meal.participants) {
        [self download:[user avatarFullUrl]];
    }
}
- (void) checkIfFinish{
    if (_finishedCounts == self.meal.participants.count + 1) { //participants + meal
        [self.delegate didFinishLoad:self.indexPathInTableView];
    }
}
@end
