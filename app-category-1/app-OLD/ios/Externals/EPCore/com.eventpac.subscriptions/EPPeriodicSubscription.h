//
//  EPPeriodicSubscription.h
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPSubscription.h"

@interface EPPeriodicSubscription : EPSubscription {
    NSString *manifestFilePath;
    NSString *contentDirPath;
    IFResource *zipResource;
    NSString *zipFilePath;
    BOOL initializing;
}

@end
