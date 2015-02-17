//
//  EPView.h
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"

@protocol EPView <EPComponent>

@property (nonatomic, strong) IFCompoundURI *viewURI;

@end
