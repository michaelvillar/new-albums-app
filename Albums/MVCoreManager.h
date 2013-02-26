//
//  MViTunesSearchManager.h
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVContextSource.h"

#define kMVCoreManagerStepIdle 0
#define kMVCoreManagerStepWaitToSync 1
#define kMVCoreManagerStepSearchingArtistIds 2
#define kMVCoreManagerStepSearchingNewAlbums 3
#define kMVCoreManagerStepHidingOwnedAlbums 4
#define kMVCoreManagerStepMarkReleasedAlbums 5

@class MVCoreManager;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MVCoreManagerDelegate
@optional
- (void)coreManagerDidStartSync:(MVCoreManager*)coreManager;
- (void)coreManagerDidFinishSync:(MVCoreManager*)coreManager;
- (void)coreManagerDidFailToSync:(MVCoreManager*)coreManager;
@end
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreManager : NSObject <MVContextSource>

@property (readonly, nonatomic, getter = hasSyncedAtLeastOnce) BOOL syncedAtLeastOnce;
@property (strong, readwrite) NSString *countryCode;
@property (readonly, getter = isSyncing) BOOL syncing;
@property (readonly) int step;
@property (readonly) float stepProgression;
@property (readonly, nonatomic) float progression;
@property (weak, readwrite) NSObject<MVCoreManagerDelegate> *delegate;

- (void)sync;

@end
