//
//  Const.h
//  EasyOrder
//
//  Created by igneus on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HostService.h"

#ifndef EasyOrder_Const_h
#define EasyOrder_Const_h

#define LOGGED_USER_PROFILE @"LOGGED_USER_PROFILE"

#define EOHOST [[HostService service] host]
#define XMPP_HOST [[HostService service] xmppHost]
#define WEIBO_APP_KEY [[HostService service] weiboAppKey]
#define WEIBO_APP_SECRET [[HostService service] weiboSecret]
#define WEIBO_APP_REDIRECT_URI [[HostService service] weiboRedirectUri]

//#define EOHOST @"fanjoin.com"
//#define XMPP_HOST EOHOST
//#define WEIBO_APP_KEY @"2295468526"
//#define WEIBO_APP_SECRET @"5991184a22eaff8d2b1149bcf1b1ff91"
//#define WEIBO_APP_REDIRECT_URI @"http://fanjoin.com/login/weibo/" 

//#define EOHOST @"t.ifunjoin.com"
//#define XMPP_HOST @"ifunjoin.com"
//#define WEIBO_APP_KEY @"1086545555"
//#define WEIBO_APP_SECRET @"edc858db52e5c2bc803010a81b183c5d"
//#define WEIBO_APP_REDIRECT_URI @"http://t.ifunjoin.com/login/weibo/"

//#define EOHOST @"localhost:8000"us
//#define XMPP_HOST @"wayne.local"
//#define WEIBO_APP_KEY @"2295468526"
//#define WEIBO_APP_SECRET @"5991184a22eaff8d2b1149bcf1b1ff91"
//#define WEIBO_APP_REDIRECT_URI @"http://fanjoin.com/login/weibo/"


#define FANJU_HOST_KEY @"FANJU_HOST_KEY"
#define HTTPS @"http" // use http for https in development
#define APP_SCHEME @"Fanju"
#define UM_SOCIAL_APP_KEY @"51bea17356240b5571083344"

#define UNREAD_MESSAGE_COUNT @"UNREAD_MESSAGE_COUNT"
#define UNREAD_NOTIFICATION_COUNT @"UNREAD_NOTIFICATION_COUNT"
#define AVATAR_UPDATED_NOTIFICATION @"AVATAR_UPDATED_NOTIFICATION"
#define UNREAD_ALL_COUNT @"UNREAD_ALL_COUNT"
#define EOUnreadCount @"EOUnreadCount"
#define LAST_MESSAGE_RETRIEVE_TIME @"LAST_MESSAGE_RETRIEVE_TIME"
#define ALIPAY_PAY_RESULT @"ALIPAY_PAY_SUCCESS"
#define NOTIFICATION_USER_UPDATE @"NOTIFICATION_USER_UPDATE"
#define WEIXIN_APP_KEY @"wx07f9e21d5eacbcb0"
#endif
