//
//  DataRetriever.h
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>

typedef void(^retrieved_t)(id);
typedef void(^retrieve_failed_t)(void);
typedef void(^upload_progress_t)(NSInteger, NSInteger);
typedef void(^download_progress_t)(NSInteger, NSInteger);
typedef enum {
    GET, POST, DELETE, PATCH
}
http_method_t;

@interface NetworkHandler : NSObject

+ (NetworkHandler *)getHandler;

- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure;

- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
            parameters:(NSArray*)params
           cachePolicy:(TTURLRequestCachePolicy)policy
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure;

- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
           cachePolicy:(TTURLRequestCachePolicy)policy
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure;

- (void)sendJSonRequest:(NSString *)url 
                 method:(http_method_t)method 
             jsonObject:(NSObject *)jsonObject
                success:(retrieved_t)success 
                failure:(retrieve_failed_t)failure ;

- (void)request:(TTURLRequest*)request
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;

-(void)uploadImage:(UIImage*)image toURL:(NSString*)url success:(retrieved_t)success  failure:(retrieve_failed_t)failure;
-(void)uploadImage:(UIImage*)image toURL:(NSString*)url success:(retrieved_t)success  failure:(retrieve_failed_t)failure progress:(upload_progress_t)progress;
@end
