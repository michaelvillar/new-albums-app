//
//  KOUAssetsManager.m
//  URLKit
//
//  Created by Michael Villar on 4/23/12.
//  Copyright (c) 2012 Noaliasing. All rights reserved.
//

#import "MVAssetsManager.h"
#import "NSString+Digest.h"
#import "MVFileDownload.h"
#import "MVAsset.h"
#import "MVAsset_Private.h"
#import "MVAssetsManager_Private.h"

static MVAssetsManager *sharedAssetsManager_ = nil;

#define kKOUAssetsCachePath @"com.kickoff.Kickoff"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAssetsManager () <KOUFileDownloadDelegate>

@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSMutableArray *fileDownloads;
@property (strong, readwrite) NSMutableDictionary *localURLsCache;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAssetsManager

@synthesize operationQueue        = operationQueue_,
            fileDownloads         = fileDownloads_,
            localURLsCache        = localURLsCache_,
            cachePath             = cachePath_;

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (MVAssetsManager*)sharedAssetsManager
{
  if(!sharedAssetsManager_)
  {
    sharedAssetsManager_ = [[MVAssetsManager alloc] init];
  }
  return sharedAssetsManager_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    operationQueue_ = [[NSOperationQueue alloc] init];
    operationQueue_.maxConcurrentOperationCount = 2;
    fileDownloads_ = [NSMutableArray array];
    localURLsCache_ = [NSMutableDictionary dictionary];
    cachePath_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isAssetExistingForRemoteURL:(NSURL*)remoteURL
{
  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                          assetsManager:self];
  return asset.isExisting;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (MVAsset*)assetForRemoteURL:(NSURL*)remoteURL
{
  MVAsset *asset = [[MVAsset alloc] initWithRemoteURL:remoteURL
                                          assetsManager:self];
  NSURL *localURL = asset.localURL;
  if(!asset.isExisting) 
  {
    BOOL existsFileDownload = NO;
    MVFileDownload *fileDownload;
    // search for an existing fileDownload
    for(fileDownload in self.fileDownloads)
    {
      if([fileDownload.destinationURL isEqual:localURL])
      {
        existsFileDownload = YES;
        break;
      } 
    }
    
    if(!existsFileDownload)
    {
      fileDownload = [[MVFileDownload alloc] initWithSourceURL:remoteURL
                                                 destinationURL:localURL 
                                                 operationQueue:self.operationQueue];
      fileDownload.delegate = self;
      [self.fileDownloads addObject:fileDownload];
      [fileDownload start];
    }
    
    asset.fileDownload = fileDownload;
  }
  return asset;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL*)resolveLocalURLForRemoteURL:(NSURL*)url
{
  if (!url) return nil;
  
  NSURL *localURL = [self.localURLsCache valueForKey:url.absoluteString];
  if(!localURL)
  {
    NSString *filename = [[url absoluteString] kou_digest];
    NSString *filePath = [[self cachePath] stringByAppendingPathComponent:filename];
    filePath = [filePath stringByAppendingPathComponent:[url lastPathComponent]];
    localURL = [NSURL fileURLWithPath:filePath];
    [self.localURLsCache setValue:localURL forKey:url.absoluteString];
  }
  return localURL;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)cachePath
{
  if(!cachePath_)
  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filePath = [paths objectAtIndex:0];
    cachePath_ = [filePath stringByAppendingPathComponent:kKOUAssetsCachePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cachePath_])
    {
      [fileManager createDirectoryAtPath:cachePath_
             withIntermediateDirectories:YES
                              attributes:nil
                                   error:nil];
    }
  }
  return cachePath_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KOUFileDownloadDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileDownloadDidFinish:(MVFileDownload *)fileDownload
{
  [self.fileDownloads removeObject:fileDownload];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileDownload:(MVFileDownload *)fileDownload didFailWithError:(NSError *)error
{
  [self.fileDownloads removeObject:fileDownload];
}

@end
