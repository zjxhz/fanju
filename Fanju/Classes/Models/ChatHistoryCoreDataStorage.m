//
//  XMPPMessageCoreDataStorage.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 11/26/12.
//
//

#import "ChatHistoryCoreDataStorage.h"

@implementation ChatHistoryCoreDataStorage

- (void)willCreatePersistentStoreWithPath:(NSString *)storePath{
    //TODO disable following lines
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if (storePath && [[NSUserDefaults standardUserDefaults] boolForKey:@"DELETE_OLD_DATA"]) {
        NSError* error = nil;
        DDLogVerbose(@"deleting chat history...");
        if(![fileMgr removeItemAtPath:storePath error:&error]){
            DDLogWarn(@"failed to delete chat history: %@", error);
        }
    }
}
@end
