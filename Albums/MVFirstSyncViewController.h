//
//  MVFirstSyncViewController.h
//  Albums
//
//  Created by Michaël Villar on 2/21/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MVContextSource;
@class MVCoreManager;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFirstSyncViewController : UIViewController

- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager;

@end