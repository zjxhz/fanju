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

@implementation UserService{
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
}
+(UserService*)shared{
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

-(User*)getOrFetchUserWithUsername:(NSString*)username success:(void (^)(User* user))success failure:(void (^)(void))failure{
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

-(User*)getOrFetchUserWithJID:(NSString*)jid success:(void (^)(User* user))success failure:(void (^)(void))failure{
    NSArray* components = [jid componentsSeparatedByString:@"@"];
    if (components.count == 0) {
        return nil;
    }
    return [self getOrFetchUserWithUsername:components[0] success:success failure:failure];
}

-(User*)userWithJID:(NSString*)jid{
    User* user = [self getOrFetchUserWithJID:jid success:nil failure:nil];
    return user;
}

-(void)fetchUser:(NSString*)username success:(void (^)(User* user))success failure:(void (^)(void))failure{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"user/"
                   parameters:@{@"user__username":username}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          DDLogVerbose(@"results from /user/");
                          NSArray* fetchedUsers = mappingResult.array;
                          NSAssert(fetchedUsers.count == 1, @"fetched not exact one user for username: %@", username);
                          User* user = fetchedUsers[0];
                          success(user);
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          DDLogError(@"failed from /user/: %@", error);
                          failure();
                      }];
}

-(User*)loggedInUser{
    if (_loggedInUser) {
        return _loggedInUser;
    }
    UserProfile* loggedInUser = [Authentication sharedInstance].currentUser;
    _loggedInUser = [self getOrFetchUserWithUsername:loggedInUser.username success:nil failure:nil];
    NSAssert(_loggedInUser, @"cannot find logged in user in core data, which should be available already when logged in");
    return _loggedInUser;
}

+(NSString*)jidForUser:(User*)user{
    NSAssert(user != nil, @"user must not be nil to get jid");
    return [NSString stringWithFormat:@"%@@%@", user.username, XMPP_HOST];
}
@end
