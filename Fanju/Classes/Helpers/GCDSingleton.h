//
//  GCDSingleton.h
//  Vobie
//
//  Created by Liu Xiaozhi on 11/17/11.
//  Copyright (c) 2011 Vobile Inc.. All rights reserved.
//

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; 