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
//#define EOHOST @"fanjoin.com"
//#define XMPP_HOST @"fanjoin.com"
//#define EOHOST @"localhost:8000"
//#define XMPP_HOST @"wayne.local"
#define EOHOST @"ifunjoin.com"
#define XMPP_HOST @"ifunjoin.com"
//#define EOHOST @"www.ifunjoin.com:8001"
#define HTTPS @"http" // use http for https in development
#define APP_SCHEME @"Fanju"
#define WEIBO_APP_KEY @"2295468526"
#define WEIBO_APP_SECRET @"5991184a22eaff8d2b1149bcf1b1ff91" 
#define WEIBO_APP_REDIRECT_URI @"http://fanjoin.com/login/weibo/"

#define UNREAD_MESSAGE_COUNT @"UNREAD_MESSAGE_COUNT"
#define UNREAD_NOTIFICATION_COUNT @"UNREAD_NOTIFICATION_COUNT"
#define AVATAR_UPDATED_NOTIFICATION @"AVATAR_UPDATED_NOTIFICATION"
#define UNREAD_ALL_COUNT @"UNREAD_ALL_COUNT"
#define EOUnreadCount @"EOUnreadCount"
#define LAST_MESSAGE_RETRIEVE_TIME @"LAST_MESSAGE_RETRIEVE_TIME"
#define ALIPAY_PAY_RESULT @"ALIPAY_PAY_SUCCESS"
#define NOTIFICATION_USER_UPDATE @"NOTIFICATION_USER_UPDATE"
#endif
