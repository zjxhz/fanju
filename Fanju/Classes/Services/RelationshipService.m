//
//  RelationshipService.m
//  Fanju
//
//  Created by Xu Huanze on 5/21/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "RelationshipService.h"
#import "User.h"
#import "Relationship.h"

@implementation RelationshipService{
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
    BOOL _relashipshipFetched;
}
+(RelationshipService*)service{
    static dispatch_once_t onceToken;
    static RelationshipService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[RelationshipService alloc] init];
    });
    return instance;
}

-(id)init{
    self = [super init];
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _contex = store.mainQueueManagedObjectContext;
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"Relationship" inManagedObjectContext:_contex];
    return self;
}

-(void)fetchFollowingsForUser:(User*)user{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    [user removeFollowings:user.followings]; //clear old data
    [manager getObjectsAtPath:@"relationship/"
                   parameters:@{@"from_person":user.uID, @"limit":@"0", @"status": @"0"} //fetch all
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          DDLogVerbose(@"results from /relationship/");
                          _relashipshipFetched = YES;
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          DDLogError(@"failed from /user/: %@", error);
                      }];
}

-(BOOL)isLoggedInUserFollowing:(User*)anotherUser{
    return [self relationWith:anotherUser] != nil;
}

-(void)follow:(User*)user{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    Relationship* r =  [NSEntityDescription insertNewObjectForEntityForName:@"Relationship" inManagedObjectContext:_contex];
    r.fromPerson = [UserService service].loggedInUser;
    r.toPerson = user;
    r.status = [NSNumber numberWithInteger:0];
    NSDictionary* params = @{@"to_person_id":user.uID};//TODO maybe we shall use request mapping instead, see RestKitService
    [manager postObject:r path:nil parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        [[UserService service].loggedInUser addFollowingsObject:r];
//        NSError* error;
//        if(![_contex saveToPersistentStore:&error]){
//            DDLogError(@"failed to save a relationship to %@", user.username);
//        }
        DDLogInfo(@"array: %@", mappingResult.array);
        DDLogInfo(@"dic: %@", mappingResult.dictionary);
        DDLogInfo(@"followed");
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        DDLogError(@"failed to follow %@: %@", user.name, error);
    }];
}

-(Relationship*)relationWith:(User*)user{
    if (!_relashipshipFetched) {
        DDLogWarn(@"relationship not fetched yet when asking relationship with user: %@", user.username);
        return nil;
    }

    User* loggedInUser = [UserService service].loggedInUser;
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"fromPerson=%@ AND toPerson=%@ AND status=0", loggedInUser, user];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch relationship for user: %@", loggedInUser.username);
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find duplicated relationship: from: %@ to: %@", loggedInUser.username, user.username);
        return objects[0];
    }
    return nil;
}
@end
