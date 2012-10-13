//
//  MVAlbumsViewController.h
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVViewController.h"

#define kMVAlbumsViewControllerTypeReleased 1
#define kMVAlbumsViewControllerTypeUpcoming 2

@protocol MVContextSource;
@class MVCoreManager;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumsViewController : MVViewController

- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
                       type:(int)type;

@end
