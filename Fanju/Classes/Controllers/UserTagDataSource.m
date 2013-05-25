//
//  UserTagDataSource.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/29/13.
//
//

#import "UserTagDataSource.h"
#import "Tag.h"
#import "UserTagCell.h"
#import "Const.h"
#import "NetworkHandler.h"
#import "DictHelper.h"

@implementation UserTagDataSource
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.row != 0;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    Tag* deletedTag = [self tableView:tableView objectForRowAtIndexPath:indexPath];    
    NSArray* params = [NSArray arrayWithObject:[DictHelper dictWithKey:@"deleted_tag" andValue:deletedTag.name]];
    User* loggedInUser = [UserService service].loggedInUser;
    NSString *requestStr = [NSString stringWithFormat:@"%@://%@/api/v1/user/%@/tags/", HTTPS, EOHOST, loggedInUser.uID];
    [[NetworkHandler getHandler] requestFromURL:requestStr
                                         method:POST //TODO: can we use delete or restkit to do the delete?
                                     parameters:params
                                    cachePolicy:TTURLRequestCachePolicyNone
                                        success:^(id obj) {
                                            NSString* resultStatus = [obj objectForKey:@"status"];
                                            if ([resultStatus isEqualToString:@"OK"]) {
                                                DDLogInfo(@"tag %@ deleted", deletedTag.name);
                                                [loggedInUser removeTagsObject:deletedTag];
                                                NSManagedObjectContext* contex = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
                                                NSError* error;
                                                if(![contex saveToPersistentStore:&error]){
                                                    DDLogError(@"failed to save after saving tags: %@", error);
                                                }
                                                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_UPDATE object:loggedInUser];
                                            } else {
                                                DDLogError(@"failed to delete tag %@: %@", deletedTag.name, resultStatus);
                                            }
                                        } failure:^{
                                            DDLogError(@"failed to delete tag %@", deletedTag.name);
                                        }];
    
    
    [self.items removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object{
    if ([object isKindOfClass:[Tag class]] || [object isKindOfClass:[NSString class]]) {
        return [UserTagCell class];
    }
    return [super tableView:tableView cellClassForObject:object];
}
@end
