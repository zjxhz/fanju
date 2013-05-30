//
//  RestKitService.m
//  Fanju
//
//  Created by Xu Huanze on 5/21/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "RestKitService.h"
#import "Const.h"
#import "DateUtil.h"
#import "Relationship.h"

@implementation RestKitService
+(RestKitService*)service{
    static dispatch_once_t onceToken;
    static RestKitService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[RestKitService alloc] init];
    });
    return instance;
}

-(void)setup{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Fanju" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Fanju.sqlite"];
    DDLogVerbose(@"Fanju.sqlite path: %@", path);
//    if(path && [[NSUserDefaults standardUserDefaults] boolForKey:@"DELETE_OLD_DATA"]){
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        [fileMgr removeItemAtPath:path error:nil];
//    }
    
    [managedObjectStore createPersistentStoreCoordinator];
    NSError* error = nil;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    if (! persistentStore) {
        DDLogError(@"Failed adding persistent store at path '%@': %@", path, error);
    }
    [managedObjectStore createManagedObjectContexts];
    [RKManagedObjectStore setDefaultStore:managedObjectStore];
    NSString* baseURL = [NSString stringWithFormat:@"http://%@/api/v1/", EOHOST];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:baseURL]];
    manager.managedObjectStore = managedObjectStore;
    [RKObjectManager setSharedManager:manager];
    
    RKEntityMapping *photoMapping = [RKEntityMapping mappingForEntityForName:@"Photo" inManagedObjectStore:managedObjectStore];
    photoMapping.identificationAttributes = @[@"pID"];
    [photoMapping addAttributeMappingsFromDictionary:@{
     @"id": @"pID",
     @"large":@"url",
     @"thumbnail":@"thumbnailURL"}];
    
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    tagMapping.identificationAttributes = @[@"tID"];
    [tagMapping addAttributeMappingsFromDictionary:@{@"id": @"tID"}];
    [tagMapping addAttributeMappingsFromArray:@[@"name"]];
    
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[@"uID"];
    [userMapping addAttributeMappingsFromDictionary:@{
     @"id": @"uID",
     @"date_joined": @"dateJoined", //interval is used when you use scalar properties in core data 下同
     @"lat": @"latitude",
     @"lng": @"longitude",
     @"weibo_id": @"weiboID",
     @"work_for":@"workFor",
     @"updated_at": @"locationUpdatedAt",
     @"background_image":@"backgroundImage",
     @"birthday": @"birthday"
     }];
    [RKObjectMapping addDefaultDateFormatterForString:LONG_TIME_FORMAT_STR inTimeZone:[NSTimeZone defaultTimeZone]];
    [RKObjectMapping addDefaultDateFormatterForString:SHORT_TIME_FORMAT_STR inTimeZone:[NSTimeZone defaultTimeZone]];
    
    [userMapping addAttributeMappingsFromArray:@[@"avatar", @"college", @"name", @"tel", @"email",
     @"gender", @"industry", @"motto", @"occupation", @"username"]];
    [userMapping addRelationshipMappingWithSourceKeyPath:@"photos" mapping:photoMapping];
    [userMapping addRelationshipMappingWithSourceKeyPath:@"tags" mapping:tagMapping];
    
    RKEntityMapping *restaurantMapping = [RKEntityMapping mappingForEntityForName:@"Restaurant" inManagedObjectStore:managedObjectStore];
    restaurantMapping.identificationAttributes = @[@"rID"];
    [restaurantMapping addAttributeMappingsFromDictionary:@{@"id": @"rID"}];
    [restaurantMapping addAttributeMappingsFromArray:@[@"address", @"latitude", @"longitude", @"name", @"tel"]];
    
    RKEntityMapping *mealMapping = [RKEntityMapping mappingForEntityForName:@"Meal" inManagedObjectStore:managedObjectStore];
    mealMapping.identificationAttributes = @[@"mID"];
    [mealMapping addAttributeMappingsFromDictionary:@{
     @"id": @"mID",
     @"actual_persons": @"actualPersons",
     @"list_price": @"price",
     @"max_persons": @"maxPersons",
     @"photo": @"photoURL",
     @"start_date": @"startDate",
     @"start_time": @"startTime"}];
    [mealMapping addAttributeMappingsFromArray:@[@"topic", @"introduction"]];
    [mealMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"restaurant" toKeyPath:@"restaurant" withMapping:restaurantMapping]];
    [mealMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"host" toKeyPath:@"host" withMapping:userMapping]];
    [mealMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"participants" toKeyPath:@"participants" withMapping:userMapping]];
    
    RKEntityMapping *orderMapping = [RKEntityMapping mappingForEntityForName:@"Order" inManagedObjectStore:managedObjectStore];
    orderMapping.identificationAttributes = @[@"oID"];
    [orderMapping addAttributeMappingsFromDictionary:@{
     @"id": @"oID",
     @"num_persons": @"numberOfPersons"
     }];
    [orderMapping addAttributeMappingsFromArray:@[@"code", @"status"]];
    [orderMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"customer" toKeyPath:@"user" withMapping:userMapping]];
    [orderMapping addRelationshipMappingWithSourceKeyPath:@"meal" mapping:mealMapping];
    
//    NSMutableDictionary* relationshipMappingDictionary = @{@"id": @"rID", @"status":@"status",@"from_person_id":@"fromPerson.uID"};
    RKEntityMapping *relationshipMapping = [RKEntityMapping mappingForEntityForName:@"Relationship" inManagedObjectStore:managedObjectStore];
    relationshipMapping.identificationAttributes = @[@"rID"];
    [relationshipMapping addAttributeMappingsFromDictionary:@{@"id": @"rID"}];
    [relationshipMapping addAttributeMappingsFromArray:@[@"status"]];
    [relationshipMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"from_person" toKeyPath:@"fromPerson" withMapping:userMapping]];
    [relationshipMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"to_person" toKeyPath:@"toPerson" withMapping:userMapping]];
    
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addAttributeMappingsFromDictionary:@{
     @"meta.limit": @"perPage",
     @"meta.total_pages": @"pageCount",
     @"meta.total_count": @"objectCount",
     }];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *mealResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mealMapping pathPattern:@"meal/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *userMealResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mealMapping pathPattern:@"user/:uID/meal/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *userOrderResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:orderMapping pathPattern:@"user/:uID/order/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *orderResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:orderMapping pathPattern:@"order/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *orderDetailsResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:orderMapping pathPattern:@"order/:oID/" keyPath:nil statusCodes:statusCodes];
    RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"user/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *userDetailResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"user/:uID/" keyPath:nil statusCodes:statusCodes];
    RKResponseDescriptor *photoResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:photoMapping pathPattern:@"userphoto/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *followingResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"user/:uID/following/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *recommendedUsersResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"user/:uID/recommendations/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *usersNearbyResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"user/:uID/users_nearby/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *usersWithSameTagResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"usertag/:tID/users/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *relationshipResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:relationshipMapping pathPattern:@"relationship/" keyPath:@"objects" statusCodes:statusCodes];
    RKResponseDescriptor *tagResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tagMapping pathPattern:@"usertag/" keyPath:@"objects" statusCodes:statusCodes];
//    RKResponseDescriptor *relationshipDetailResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:relationshipMapping pathPattern:@"relationship/:rID/" keyPath:nil statusCodes:statusCodes];
//    RKObjectMapping *relationshipRequestMapping = [RKObjectMapping requestMapping];
//    [relationshipRequestMapping addAttributeMappingsFromDictionary:relationshipMappingDictionary];
//    relationshipRequestMapping addre
//     = [relationshipMapping addAttributeMappingsFromDictionary:userMappingDictionary];
//    RKRequestDescriptor *relationshipRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:[relationshipMapping inverseMapping] objectClass:[Relationship class] rootKeyPath:nil];
    [manager addResponseDescriptor:mealResponseDescriptor];
    [manager addResponseDescriptor:userMealResponseDescriptor];
    [manager addResponseDescriptor:userResponseDescriptor];
    [manager addResponseDescriptor:userDetailResponseDescriptor];
    [manager addResponseDescriptor:photoResponseDescriptor];
    [manager addResponseDescriptor:followingResponseDescriptor];
    [manager addResponseDescriptor:recommendedUsersResponseDescriptor];
    [manager addResponseDescriptor:usersNearbyResponseDescriptor];
    [manager addResponseDescriptor:usersWithSameTagResponseDescriptor];
    [manager addResponseDescriptor:orderResponseDescriptor];
    [manager addResponseDescriptor:orderDetailsResponseDescriptor];
    [manager addResponseDescriptor:userOrderResponseDescriptor];    
    [manager addResponseDescriptor:relationshipResponseDescriptor];
    [manager addResponseDescriptor:tagResponseDescriptor];
//    [manager addRequestDescriptor:relationshipRequestDescriptor];
    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[Photo class] pathPattern:@"userphoto/:pID/" method:RKRequestMethodGET | RKRequestMethodDELETE]];
    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[Relationship class] pathPattern:@"relationship/" method:RKRequestMethodPOST]];
    [manager setPaginationMapping:paginationMapping];
    
}
@end
