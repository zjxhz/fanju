//
//  DataRetriever.m
//  EasyOrder
//
//  Created by igneus on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetworkHandler.h"
#import "SVProgressHUD.h"
#import "Authentication.h"
#import "AppDelegate.h"
#import "JSONKit.h"

static NSMutableArray *pool;
static int t = 0;

@interface NetworkHandler (){
    NSMutableArray* _callbacks;//dictionary whose key is the url, and the value is a pair of the success/fail block objects
}
@property (nonatomic, strong) retrieved_t success;
@property (nonatomic, strong) retrieve_failed_t failure;
@property (nonatomic, strong) upload_progress_t upload_progress;
@property (nonatomic) BOOL available;
@property (nonatomic) int tag;
@end

@implementation NetworkHandler
@synthesize available = _available;
@synthesize tag = _tag;


+ (NetworkHandler *)getHandler {
    if (!pool) {
        pool = [NSMutableArray array];
    }
    
    NetworkHandler *avail = nil;
    for(NetworkHandler *handler in pool) {
        if(handler.available) {
            avail = handler;
            avail.available = NO;
            DDLogVerbose(@"fetching NetworkHandler from the pool: %@", avail);
            break;
        }
    }
    
    if (!avail) {
        avail = [[NetworkHandler alloc] init];
        avail.tag = t++;
        avail.available = NO;
        [pool addObject:avail];
        DDLogVerbose(@"creating a new NetworkHandler: %@", avail);
    }
    
    return avail;
}

-(id)init{
    if (self = [super init]) {
        _callbacks = [NSMutableArray array];
    }
    return self;
}
- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure {
    [self requestFromURL:url
                  method:method
              parameters:nil
             cachePolicy:TTURLRequestCachePolicyEtag
                 success:success
                 failure:failure];
}

- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
           cachePolicy:(TTURLRequestCachePolicy)policy
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure; {
    
    [self requestFromURL:url
                  method:method
              parameters:nil 
             cachePolicy:policy
                 success:success
                 failure:failure];
}

- (void)requestFromURL:(NSString *)url 
                method:(http_method_t)method 
            parameters:(NSArray *)params
           cachePolicy:(TTURLRequestCachePolicy)policy
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure {
    self.success = [success copy];
    self.failure = [failure copy];
    
    TTURLRequest* request = [TTURLRequest requestWithURL:url 
                                                delegate:self];
    
    request.cachePolicy = policy; 
    request.response = [[TTURLDataResponse alloc] init];
    NSMutableString *paramStr = [[NSMutableString alloc] init];
    if (method == GET) {
        request.httpMethod = @"GET"; 
    } else  {
        if (params) {

            for (int i = 0; i < params.count; ++i) {
                NSDictionary *dict = [params objectAtIndex:i];
                NSString *value = [dict objectForKey:@"value"];
                NSString *key = [dict objectForKey:@"key"];
                [request.parameters setValue:value forKey:key];    
                [paramStr appendFormat:@"%@=%@", key, value];
                if (i != params.count - 1) {
                    [paramStr appendString:@"&"];
                }
            }
        } else {
            request.httpBody = [NSData data];
        }
        if (method == POST){
            request.httpMethod = @"POST";
        } else if (method == DELETE){
            request.httpMethod = @"DELETE";
        } else if (method == PATCH){
            request.httpMethod = @"PATCH";
        }
        else {
            DDLogVerbose(@"Not supported method %d", method);
        }
        NSMutableString *logStr = [NSMutableString stringWithFormat:@"%@ %@",request.httpMethod, url];
        if (params) {
            [logStr appendFormat:@"?%@",paramStr];
        }
        
        DDLogVerbose(logStr);
    }
    
    [request send];
}


-(void)uploadImage:(UIImage*)image withName:(NSString*)filename toURL:(NSString*)url success:(retrieved_t)success  failure:(retrieve_failed_t)failure progress:(upload_progress_t)progress{
    self.success = [success copy];
    self.failure = [failure copy];
    self.upload_progress = progress;
    
    TTURLRequest* request = [TTURLRequest requestWithURL:[NSString stringWithFormat:@"http://%@/api/v1/%@", EOHOST, url]
                                                delegate:self];
    request.httpMethod = @"POST";
    request.cachePolicy= TTURLRequestCachePolicyNone;
    request.response = [[TTURLDataResponse alloc] init];
    
    NSData* file = UIImageJPEGRepresentation(image, 1.0);
    [request addFile:file mimeType:@"image/jpeg" fileName:filename];
    DDLogVerbose(@"uploading file...");
    
    [request send];
}



- (void)sendJSonRequest:(NSString *)url 
                method:(http_method_t)method 
              jsonObject:(id)jsonObject
               success:(retrieved_t)success 
               failure:(retrieve_failed_t)failure {
    self.success = [success copy];
    self.failure = [failure copy];
    
    TTURLRequest* request = [TTURLRequest requestWithURL:url 
                                                delegate:self];
    request.cachePolicy= TTURLRequestCachePolicyNone;
    request.response = [[TTURLDataResponse alloc] init];
    request.httpBody = [jsonObject JSONData];//[[jsonObject JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
    if (method == POST){
        request.httpMethod = @"POST";
    } else if (method == DELETE){
        request.httpMethod = @"DELETE";
    } else if (method == PATCH){
        request.httpMethod = @"PATCH";
    }
    else {
        DDLogVerbose(@"Not supported method %d", method);
    }
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request send];
}

#pragma mark TTURLRequestDelegate
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    DDLogVerbose(@"request did finish load for NetworkHandler: %@", self);
    NSData *data = [(TTURLDataResponse*)request.response data];
    id obj = [data objectFromJSONData];//[parser objectWithData:data];
    if (data.length >0 && !obj) {
        NSString* html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DDLogVerbose(@"no json data found, probably error occured, html: %@", html);
    }
    if (self.success != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.success(obj);
            self.available = YES;
        });
    }

}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData * data = [error.userInfo objectForKey:@"responsedata"];
//                DDLogVerbose([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]) ;
        NSString* html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSString* errorPage = [NSString stringWithFormat:@"%@/error.html", NSTemporaryDirectory()];
        [html writeToFile:errorPage atomically:NO encoding:NSUTF8StringEncoding error:nil];
        DDLogError(@"request failed with error: %@", error);
        DDLogError(@"Network Error: error page saved to %@", errorPage);
        if (self.failure != NULL) {
            self.failure();
        }
        self.available = YES;
    });
    

}

/**
 * Allows delegate to handle any authentication challenges.
 */
- (void)request:(TTURLRequest*)request
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge{
    DDLogVerbose(@"received challenge: %@", challenge);
}

- (void)requestDidUploadData:(TTURLRequest*)request{
    if (self.upload_progress != NULL) {
        self.upload_progress(request.totalBytesLoaded, request.totalBytesExpected);
    }
//    DDLogVerbose(@"uploading %d/%d: %.2f%%", request.totalBytesLoaded, request.totalBytesExpected, request.totalBytesLoaded * 100.0 / request.totalBytesExpected);
}
@end
