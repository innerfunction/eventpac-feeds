//
//  IFCore.h
//  EventPacComponents
//
//  Created by Julian Goacher on 30/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#ifndef EventPacComponents_IFCore_h
#define EventPacComponents_IFCore_h

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

#define IFCoreLogLevel                  LOG_LEVEL_VERBOSE
#define MainBundlePath                  ([[NSBundle mainBundle] resourcePath])

#define IFNotificationFileUpdate        @"IFNotificationFileUpdate"
#define IFNotificationLocalDataUpdate   @"IFNotificationLocalDataUpdate"

#define Retina4DisplayHeight            568
#define IsIPhone                        ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IsRetina4                       ([[UIScreen mainScreen] bounds].size.height == Retina4DisplayHeight)

#define ToastMessageDuration            1.0

#endif
