//
//  KOUAsset.h
//  URLKit
//
//  Created by Michael Villar on 4/23/12.
//  Copyright (c) 2012 Noaliasing. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVAssetsManager;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAsset : NSObject

@property (strong, readonly) NSURL *localURL;
@property (strong, readwrite) NSURL *remoteURL;
@property (readonly, getter = isExisting) BOOL existing;
@property (readonly) float downloadPercentage;
@property (readonly, nonatomic) BOOL error;

- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager;
- (void)retryDownload;

@end
