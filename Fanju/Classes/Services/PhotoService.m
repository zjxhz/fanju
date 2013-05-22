//
//  PhotoService.m
//  Fanju
//
//  Created by Xu Huanze on 5/13/13.
//  Copyright (c) 2013 Wayne. All rights reserved.
//

#import "PhotoService.h"
#import "RestKit.h"
#import "Photo.h"
#import "DateUtil.h"
#import "UserService.h"

@implementation PhotoService{
    NSManagedObjectContext* _contex;
    NSFetchRequest* _fetchRequest;
}

+(PhotoService*)service{
    static dispatch_once_t onceToken;
    static PhotoService* instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[PhotoService alloc] init];
    });
    return instance;
}


-(id)init{
    self = [super init];
    RKManagedObjectStore* store = [RKObjectManager sharedManager].managedObjectStore;
    _contex = store.mainQueueManagedObjectContext;
    _fetchRequest = [[NSFetchRequest alloc] init];
    _fetchRequest.entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:_contex];
    return self;
}

-(Photo*)getOrFetchPhoto:(NSString*)photoID success:(fetch_photo_success)success failure:(void (^)(void))failure{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"pID=%@", photoID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch photo(%@) from coredata", photoID);
    } else if(objects.count == 0){
        DDLogVerbose(@"photo %@ not found in core data, fetching from server", photoID);
        [self fetchPhotoWithID:photoID success:success failure:failure];
    } else if(objects.count  > 0){
        NSAssert(objects.count == 1, @"find more than one photoID with same ID");
        return objects[0];
    }
    return nil;
}


-(void)fetchPhotoWithID:(NSString*)mID success:(void (^)(Photo* meal))success failure:(void (^)(void))failure{
    RKObjectManager *manager = [RKObjectManager sharedManager];
    [manager getObjectsAtPath:@"userphoto/"
                   parameters:@{@"id":mID}
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          DDLogVerbose(@"results from /userphoto/");
                          NSArray* fetchedPhotos = mappingResult.array;
                          if (fetchedPhotos.count == 0) {
                              DDLogWarn(@"not photo with ID %@ found, deleted?", mID);
                              failure();
                          } else {
                              NSAssert(fetchedPhotos.count == 1, @"fetched not exact one meal for ID: %@", mID);
                              Photo* photo = fetchedPhotos[0];
                              photo.user = [UserService service].loggedInUser;
                              success(photo);
                          }
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          DDLogError(@"failed from /meal/: %@", error);
                          failure();
                      }];
}

//fetch meal from core data, nil if not exist
-(Photo*)photoWithID:(NSString*)pID{
    _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"pID=%@", pID];
    NSError* error = nil;
    NSArray* objects = [_contex executeFetchRequest:_fetchRequest error:&error];
    if (error) {
        DDLogError(@"ERROR: failed to fetch photo(%@) from coredata", pID);
    } else if(objects.count > 0){
        NSAssert(objects.count == 1, @"find more than one photo with same ID");
        return objects[0];
    }
    return nil;
}

@end
