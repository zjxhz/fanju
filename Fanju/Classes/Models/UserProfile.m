//
//  UserProfile.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserProfile.h"
#import "NSDictionary+ParseHelper.h"
#import "DateUtil.h"
#import "LocationProvider.h"
#import "ModelHelper.h"
#import "Const.h"
#import "NSData+Base64.h"
#import "UserPhoto.h"

#define UNKNOWN_OR_EMPTY_STRING @"保密"

@implementation UserProfile

//@synthesize name = _name, username = _username, password = _password, uID = _uID, avatarURL = _avatarURL, gender = _gender, birthday = _birthday, locationUpdatedTime = _locationUpdatedTime, coordinate = _coordinate, motto = _motto, occupation=_occupation, college=_college, followings=_followings, tags = _tags, workFor=_workFor, email=_email, dateJoined=_dateJoined, weiboID = _weiboID, avatar = _avatar, photos = _photos;

- (UserProfile*) init{
    if (self = [super init]) {
        _gender = -1; // TODO it is better to use 0 as unknown, and then for example 1 for male, 2 for female, as it is consistent with nil design
        _tags = [NSMutableArray array];
    }
    return self;
}

- (UserProfile *)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _username = [data objectForKey:@"username"];
        _name = [ModelHelper stringValueForKey:@"name" inDictionary:data withDefaultValue:_username];
        _uID = [[data objectForKey:@"id"] intValue];
        _avatarURL = [ModelHelper stringValueForKey:@"big_avatar" inDictionary:data];//TODO currently use big avatar only
        _smallAvatarURL = [ModelHelper stringValueForKey:@"small_avatar" inDictionary:data];
        _gender = [[data objectForKey:@"gender"] isKindOfClass:[NSNull class]] ?  -1 : [[data objectForKey:@"gender"] intValue];
        _birthday = [ModelHelper dateValueForKey:@"birthday" inDictionary:data];
        id obj = [data objectForKey:@"lng"];
        if (obj && ![obj isKindOfClass:[NSNull class]]) {
            _coordinate.longitude = [obj doubleValue];
        }
        obj = [data objectForKey:@"lat"];
        if (obj && ![obj isKindOfClass:[NSNull class]]) {
            _coordinate.latitude = [obj doubleValue];
        }
        _locationUpdatedTime = [ModelHelper dateValueForKey:@"updated_at" inDictionary:data];
        _motto = [ModelHelper stringValueForKey:@"motto" inDictionary:data withDefaultValue:@""];
        _occupation = [ModelHelper stringValueForKey:@"occupation" inDictionary:data withDefaultValue:@""];
        _college = [ModelHelper stringValueForKey:@"college" inDictionary:data];
        
        _followings = [NSMutableSet set];
        for (NSString *followingUserUrl in [data objectForKey:@"following"]) {
            [_followings addObject:[self findUserIDFromUrl:followingUserUrl]];
        }
    
        _tags =[NSMutableArray array];
        for (NSDictionary *dict in [data objectForKey:@"tags"]) {
            [_tags addObject: [[UserTag alloc] initWithData:dict]];
        }
        
        _workFor = [ModelHelper stringValueForKey:@"work_for" inDictionary:data]; 
        _email = [ModelHelper stringValueForKey:@"email" inDictionary:data];
        _dateJoined = [ModelHelper dateValueForKey:@"date_joined" inDictionary:data];
        _weiboID = [ModelHelper stringValueForKey:@"weibo_id" inDictionary:data];
        _password = [ModelHelper stringValueForKey:@"password" inDictionary:data];//is it really safe to store pasword?
        
        _photos = [NSMutableArray array];
        for (NSDictionary *dict in [data objectForKey:@"photos"]) {
            [_photos addObject:[UserPhoto photoWithData:dict]];
        }
        _industry = [self parseIndustry:[[data objectForKey:@"industry"] isKindOfClass:[NSNull class]] ?  -1 : [[data objectForKey:@"industry"] intValue]];
    }
    
    return self;
}

+(NSArray*) industries{
    static NSArray* industries = nil;
    if (!industries) {
        industries = @[@"计算机/互联网/通信", @"公务员/事业单位", @"教师", @"医生", @"护士",@"空乘人员",@"生产/工艺/制造", \
        @"商业/服务业/个体经营", @"金融/银行/投资/保险", @"文化/广告/传媒", @"娱乐/艺术/表演", @"律师/法务", @"教育/培训/管理咨询",\
        @"建筑/房地产/物业", @"消费零售/贸易/交通物流", @"酒店旅游", @"现代农业", @"在校学生", @"无"];
    }
    return industries;
}

-(NSString*)parseIndustry:(NSInteger)industry{
    if (industry == -1) {
        return [[UserProfile industries] lastObject];
    }
    return [[UserProfile industries] objectAtIndex:industry];
}

-(NSInteger)industryValue{
    return [UserProfile industryValue:_industry];
}

+(NSInteger)industryValue:(NSString*)industry{
    return [[UserProfile industries] indexOfObject:industry];
}

-(NSString*)name{
    return _name ? _name : _username;
}

- (BOOL)isFollowing:(UserProfile*)user{
    for (NSString* userID in _followings) {
        if ([userID intValue] == user.uID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)hasName{
    return _name.length > 0 && ![_name isEqualToString:_username];
}

-(BOOL)hasCompletedRegistration{
    return YES;
//    return [self hasName] && _gender != -1 && _birthday && _email.length > 0 && _avatarURL.length > 0 && _tags.count >= 3;
}

-(NSString*)findUserIDFromUrl:(NSString*)url{
    NSString *resourceUrl = @"/api/v1/user/";
    NSString *userID = [url substringWithRange:NSMakeRange(resourceUrl.length, url.length - 1 - resourceUrl.length)];
    return userID;
}

+ (UserProfile *)profileWithData:(NSDictionary *)data {
    return [[UserProfile alloc] initWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    UserProfile *info = [[UserProfile allocWithZone:zone] init];
    info.name = _name;
    info.username = _username;
    info.uID = _uID;
    info.avatarURL = _avatarURL;
    info.smallAvatarURL = _smallAvatarURL;
    info.gender = _gender;
    info.birthday = _birthday;
    info.coordinate = _coordinate;
    info.locationUpdatedTime = _locationUpdatedTime;
    info.motto = _motto;
    info.occupation = _occupation;
    info.college = _college;
    info.tags = _tags;
    info.workFor = _workFor;
    info.dateJoined = _dateJoined;
    info.weiboID = _weiboID;
    info.tags = _tags;
    info.password = _password;
    info.email = _email;
    info.photos = _photos;
    return info;
}

-(BOOL) isEqual:(id)object{
    if(object && [object isKindOfClass:[UserProfile class]]){
        UserProfile *anotherUser = object;
        return _uID == anotherUser.uID;
    }
    return NO;
}

- (NSUInteger)hash{
    return _uID;
}

- (NSInteger) age {
    return [DateUtil ageFromBirthday:_birthday];
}

-(NSString*)constellation{
    return [DateUtil constellationFromBirthday:_birthday];
}

-(NSString*)tagsToString{
    return [UserTag tagsToString:_tags];
}

-(UIImage*)genderImage{
    return [UIImage imageNamed:_gender? @"female" : @"male"];
}
-(NSString*)avatarFullUrl{
    if (_avatarURL) {
        if ([_avatarURL hasPrefix:@"http:"]) {
            return _avatarURL;
        } else {
            return [NSString stringWithFormat:@"http://%@%@", EOHOST, _avatarURL];
        }
        return [NSString stringWithFormat:@"http://%@%@", EOHOST, _avatarURL];
    } else {
        return nil;
    }
}

-(NSString*)smallAvatarFullUrl{
    if (_smallAvatarURL) {
        if ([_smallAvatarURL hasPrefix:@"http:"]) {
            return _smallAvatarURL;
        } else {
            return [NSString stringWithFormat:@"http://%@%@", EOHOST, _smallAvatarURL];
        }
    } else {
        return nil;
    }
}

-(void)addPhoto:(UserPhoto*)photo{
    if (!_photos) {
        _photos = [NSMutableArray array];
    }
    [_photos addObject:photo];
}

-(NSArray*)avatarAndPhotosFullUrls{
    NSMutableArray* fullUrls = [NSMutableArray array];
    if (self.avatarURL) {
            [fullUrls addObject:[self avatarFullUrl]];
    }
    for (UserPhoto* photo in _photos) {
        [fullUrls addObject:[NSString stringWithFormat:@"http://%@%@", EOHOST, photo.url]];
    }
    return fullUrls;
}

-(NSArray*)photosFullUrls{
    NSMutableArray* fullUrls = [NSMutableArray array];
    for (UserPhoto* photo in _photos) {
        [fullUrls addObject:[NSString stringWithFormat:@"http://%@%@", EOHOST, photo.url]];
    }
    return fullUrls;
}

-(NSArray*)avatarAndPhotoThumbnailFullUrls{
    NSMutableArray* fullUrls = [NSMutableArray array];
    if (self.avatarURL) {
        [fullUrls addObject:[self smallAvatarFullUrl]];
    }
    for (UserPhoto* photo in _photos) {
        [fullUrls addObject:[NSString stringWithFormat:@"http://%@%@", EOHOST, photo.thumbnailUrl]];
    }
    return fullUrls;
}

-(NSDictionary*)avatarDictForUploading:(UIImage*)image{
    NSString* base64Img = [UIImageJPEGRepresentation(image, 1.0) base64EncodedString];
    NSString* fileName = [NSString stringWithFormat:@"%@_avatar.jpg", _username];
    NSString* contentType = @"image/jpg";
    return [NSDictionary dictionaryWithObjectsAndKeys:base64Img, @"file", 
                          contentType, @"content_type", 
                          fileName, @"name",  nil];
}

#pragma mark _
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_username forKey:@"username"];
    [coder encodeInt:_uID forKey:@"uID"];
    [coder encodeObject:_avatarURL forKey:@"avatarURL"];
    [coder encodeObject:_smallAvatarURL forKey:@"smallAvatarURL"];
    [coder encodeInt:_gender forKey:@"gender"];
    [coder encodeObject:_birthday forKey:@"birthday"];
    [coder encodeObject:_locationUpdatedTime forKey:@"locationUpdatedtime"];
    [coder encodeObject:_motto forKey:@"motto"];
    [coder encodeDouble:_coordinate.latitude forKey:@"latitude"];
    [coder encodeDouble:_coordinate.longitude forKey:@"longitude"];
    [coder encodeObject:_occupation forKey:@"occupation"];
    [coder encodeObject:_college forKey:@"college"];
    [coder encodeObject:_followings ? _followings : [NSMutableArray array] forKey:@"followings"];
    [coder encodeObject:_tags ? _tags : [NSMutableArray array] forKey:@"tags"];
    [coder encodeObject:_workFor forKey:@"workFor"];
    [coder encodeObject:_dateJoined forKey:@"dateJoined"];
    [coder encodeObject:_email forKey:@"email"];
    if (_weiboID) {
        [coder encodeObject:_weiboID forKey:@"weiboID"];
    }
    if (_password) {
        [coder encodeObject:_password  forKey:@"password"];
    }
    [coder encodeObject:_photos ? _photos : [NSMutableArray array] forKey:@"photos"];
}

- (id)initWithCoder:(NSCoder *)coder{
    if(self) {
        _name = [coder decodeObjectForKey:@"name"];
        _username =  [coder decodeObjectForKey:@"username"];
        _uID =  [coder decodeIntForKey:@"uID"];
        _avatarURL =  [coder decodeObjectForKey:@"avatarURL"];
        _smallAvatarURL = [coder decodeObjectForKey:@"smallAvatarURL"];
        _gender = [coder decodeIntForKey:@"gender"];
        _birthday = [coder decodeObjectForKey:@"birthday"];
        _motto = [coder decodeObjectForKey:@"motto"];
        
        _coordinate.latitude = [coder decodeDoubleForKey:@"latitude"];
        _coordinate.longitude  = [coder decodeDoubleForKey:@"longitude"];
        _locationUpdatedTime = [coder decodeObjectForKey:@"locationUpdatedtime"];
        if ([[LocationProvider sharedProvider] lastLocation].coordinate.latitude != 0) {
            _coordinate = [[LocationProvider sharedProvider] lastLocation].coordinate;
            _locationUpdatedTime = [LocationProvider sharedProvider].lastLocationUpdatedTime;
        }        
        
        _occupation = [coder decodeObjectForKey:@"occupation"];
        _college = [coder decodeObjectForKey:@"college"];
        _followings = [coder decodeObjectForKey:@"followings"];
        if (!_followings) {
            _followings = [NSMutableSet set];
        }
        _tags = [coder decodeObjectForKey:@"tags"];
        if (!_tags){
            _tags = [NSMutableArray array];
        }
        _workFor = [coder decodeObjectForKey:@"workFor"];
        _dateJoined = [coder decodeObjectForKey:@"dateJoined"];
        _weiboID = [coder decodeObjectForKey:@"weiboID"];
        _password = [coder decodeObjectForKey:@"password"];
        _email = [coder decodeObjectForKey:@"email"];
        _photos = [coder decodeObjectForKey:@"photos"];
    }
    
    return self;
}

-(NSString*)jabberID{
    NSString* user = [_username stringByReplacingOccurrencesOfString:@"@" withString:@"\\40"];
    return [NSString stringWithFormat:@"%@%@", user, @"@fanjoin.com"];
   
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@(%d)",_name,_uID];
}
@end
