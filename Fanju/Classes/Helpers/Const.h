//
//  Const.h
//  EasyOrder
//
//  Created by igneus on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#ifndef EasyOrder_Const_h
#define EasyOrder_Const_h

#define LOGGED_USER_PROFILE @"LOGGED_USER_PROFILE"

//#define EOHOST [[NSUserDefaults standardUserDefaults] objectForKey:@"HOST"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"HOST"] : @"www.fanjoin.com"
#define EOHOST @"www.fanjoin.com"
//#define EOHOST @"localhost:8000"
#define HTTPS @"http" // use http for https in development

#define WEIBO_APP_KEY @"4071331500"
#define WEIBO_APP_SECRET @"5cf4910b217617cee72b2889a8e394eb"
#define WEIBO_APP_REDIRECT_URI @"http://www.fanjoin.com/login/weibo/"

#define BLAME_NETWORK_ERROR_MESSAGE @"出错了，网络问题？"
#define PAGE_LIMIT 5 //number of items to be shown in one page
#define UNREAD_MESSAGE_COUNT @"UNREAD_MESSAGE_COUNT"
#define UNREAD_NOTIFICATION_COUNT @"UNREAD_NOTIFICATION_COUNT"
#define UNREAD_ALL_COUNT @"UNREAD_ALL_COUNT"
#define EOUnreadCount @"EOUnreadCount"
#define LAST_MESSAGE_RETRIEVE_TIME @"LAST_MESSAGE_RETRIEVE_TIME"
#endif
