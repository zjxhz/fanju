//
//  UserService.m
//  Fanju
//
//  Created by Xu Huanze on 5/2/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "UserService.h"
#import "RestKit.h"
#import "Authentication.h"
#import "URLService.h"
#import "Photo.h"
@implementation UserService{
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
}
+(UserService*)service{
    static UserService* instance = nil;
    if (!instance) {
        instance = [[UserService alloc] init];
    }
    return instance;
}

-(id)init{
    self = [super init];
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _contex = store.mainQueueManagedObjectContext;
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_contex];
    return self;
}

-(void)setup{
}
-(void)tearDown{
    _loggedInUser = nil;
}
-(User*)getOrFetchUserWithUsername:(NSString*)username success:(fetch_user_success)success failure:(void (^)(void))failure{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"username=%@", username];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch user(%@) from coredata", username);
    } else if(objects.count == 0){
        DDLogVerbose(@"user %@ not found in core data, fetching from server", username);
        [self fetchUser:username success:success failure:failure];
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one user with same username");
        return objects[0];
    }
    return nil;
}

-(User*)getOrFetchUserWithJID:(NSString*)jid success:(fetch_user_success)success failure:(void (^)(void))failure{
    NSArray* components = [jid componentsSeparatedByString:@"@"];
    if (components.count == 0) {
        return nil;
    }
    return [self getOrFetchUserWithUsername:components[0] success:success failure:failure];
}

-(User*)getOrFetchUserWithID:(NSString*)uID success:(fetch_user_success)success failure:(void (^)(void))failure{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uID=%@", uID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch user(%@) from coredata", uID);
    } else if(objects.count == 0){
        DDLogVerbose(@"user %@ not found in core data, fetching from server", uID);
        [self fetchUserWithID:uID success:success failure:failure];
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one user with same username");
        return objects[0];
    }
    return nil;
    
}

-(void)fetchUserWithID:(NSString*)uID success:(fetch_user_success)success failure:(void (^)(void))failure{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    NSString* url = [NSString stringWithFormat:@"user/%@/", uID];
    [manager getObject:nil path:url parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        DDLogVerbose(@"results from url: %@", url);
        User* user = mappingResult.firstObject;
        success(user);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        DDLogError(@"failed from url: %@ with error: %@", url, error);
        failure();
    }];
}

//fetch user from core data, nil if not exist
-(User*)userWithJID:(NSString*)jid{
    NSString* username = [jid componentsSeparatedByString:@"@"][0];
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"username=%@", username];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch user(%@) from coredata", username);
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one user with same username");
        return objects[0];
    }
    return nil;
}

-(User*)userWithID:(NSString*)userID{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uID=%@", userID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch user(ID:%@) from coredata", userID);
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one user with same username");
        return objects[0];
    }
    return nil;
}


-(void)fetchUser:(NSString*)username success:(fetch_user_success)success failure:(void (^)(void))failure{
    if ([username isEqualToString:[NSString stringWithFormat:@"pubsub.%@", XMPP_HOST]]) {
        NSAssert(NO, @"pubsub user does not exist.");
    }
    RKObjectManager *manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"user/"
                   parameters:@{@"username":username}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          DDLogVerbose(@"results from /user/");
                          NSArray* fetchedUsers = mappingResult.array;
                          NSAssert(fetchedUsers.count == 1, @"fetched %d user(s) for username: %@", fetchedUsers.count, username);
                          User* user = fetchedUsers[0];
                          success(user);
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          DDLogError(@"failed from /user/: %@", error);
                          failure();
                      }];
}

-(void)fetchUserWithJID:(NSString*)jid success:(fetch_user_success)success failure:(void (^)(void))failure{
    NSString* username = [jid componentsSeparatedByString:@"@"][0];
    [self fetchUser:username success:success failure:failure];
}

-(BOOL)isLoggedIn{
    return _loggedInUser != nil;
}

-(User*)loggedInUser{
    if (_loggedInUser) {
        return _loggedInUser;
    }
    UserProfile* loggedInUser = [Authentication sharedInstance].currentUser;
    _loggedInUser = [self userWithID:[NSString stringWithFormat:@"%d",loggedInUser.uID]];
    NSAssert(_loggedInUser, @"cannot find logged in user in core data, which should be available already when logged in");
    return _loggedInUser;
}

+(NSString*)jidForUser:(User*)user{
    NSAssert(user != nil, @"user must not be nil to get jid");
    return [NSString stringWithFormat:@"%@@%@", user.username, XMPP_HOST];
}

+(NSString*)avatarURLForUser:(User*)user{
    return [URLService absoluteURL:user.avatar];
}

+(NSArray*)photosUrlsForUser:(User*)user{
    NSMutableArray* fullUrls = [NSMutableArray array];
    for (Photo* photo in user.photos) {
        [fullUrls addObject:[URLService absoluteURL:photo.url]];
    }
    return fullUrls;
}

+(UIImage*)genderImageForUser:(User*)user{
    return [UIImage imageNamed:[user.gender boolValue] ? @"female" : @"male"];
}

+(NSString*)genderTextForUser:(User*)user{
    if (user.gender == 0) {
        return @"男";
    } else {
        return @"女";
    }
}
@end
