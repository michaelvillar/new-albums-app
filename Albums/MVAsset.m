//
//  KOUAsset.m
//  URLKit
//
//  Created by Michael Villar on 4/23/12.
//  Copyright (c) 2012 Noaliasing. All rights reserved.
//

#import "MVAsset.h"
#import "MVAsset_Private.h"
#import "MVFileDownload.h"
#import "MVAssetsManager_Private.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAsset ()

@property (strong, readwrite) MVAssetsManager *assetsManager;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAsset

@synthesize localURL          = localURL_,
            remoteURL         = remoteURL_,
            existing          = existing_,
            fileDownload      = fileDownload_,
            assetsManager     = assetsManager_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithRemoteURL:(NSURL*)remoteURL
          assetsManager:(MVAssetsManager*)assetsManager
{
  self = [super init];
  if(self)
  {
    localURL_ = nil;
    remoteURL_ = remoteURL;
    existing_ = NO;
    fileDownload_ = nil;
    assetsManager_ = assetsManager;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)retryDownload
{
  if(!self.error || !self.fileDownload || self.isExisting)
    return;
  MVFileDownload *fileDownload = self.fileDownload;
  MVFileDownload *newFileDownload = [[MVFileDownload alloc]
                                     initWithSourceURL:fileDownload.sourceURL
                                        destinationURL:fileDownload.destinationURL
                                        operationQueue:fileDownload.operationQueue];
  [self willChangeValueForKey:@"error"];
  self.fileDownload = newFileDownload;
  [newFileDownload start];
  [self didChangeValueForKey:@"error"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  if(fileDownload_)
  {
    [fileDownload_ removeObserver:self forKeyPath:@"downloadPercentage"];
    [fileDownload_ removeObserver:self forKeyPath:@"finished"];
    [fileDownload_ removeObserver:self forKeyPath:@"error"];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isExisting
{
  if(!existing_)
    existing_ = [[NSFileManager defaultManager] fileExistsAtPath:[self.localURL path]];
  return existing_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (float)downloadPercentage
{
  if(self.fileDownload)
    return self.fileDownload.downloadPercentage;
  return (self.isExisting ? 100 : 0);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL*)localURL
{
  if(!localURL_)
  {
    localURL_ = [self.assetsManager resolveLocalURLForRemoteURL:self.remoteURL];
  }
  return localURL_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)error
{
  return (self.fileDownload ? self.fileDownload.error : NO);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
  __strong __block MVAsset *myAsset = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    if([keyPath isEqualToString:@"downloadPercentage"])
    {
      [myAsset willChangeValueForKey:@"downloadPercentage"];
      [myAsset didChangeValueForKey:@"downloadPercentage"];
    }
    else if([keyPath isEqualToString:@"uploadPercentage"])
    {
      [myAsset willChangeValueForKey:@"uploadPercentage"];
      [myAsset didChangeValueForKey:@"uploadPercentage"];
    }
    else if([keyPath isEqualToString:@"finished"])
    {
      [myAsset willChangeValueForKey:@"existing"];
      [myAsset didChangeValueForKey:@"existing"];
    }
    else if([keyPath isEqualToString:@"error"] &&
            (object == myAsset.fileDownload))
    {
      [myAsset willChangeValueForKey:@"error"];
      [myAsset didChangeValueForKey:@"error"];
    }
    myAsset = nil;
  });
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFileDownload:(MVFileDownload *)fileDownload
{
  if(fileDownload == fileDownload_)
    return;
  [fileDownload_ removeObserver:self forKeyPath:@"downloadPercentage"];
  [fileDownload_ removeObserver:self forKeyPath:@"finished"];
  [fileDownload_ removeObserver:self forKeyPath:@"error"];
  fileDownload_ = fileDownload;
  if(fileDownload)
  {
    [fileDownload addObserver:self 
                   forKeyPath:@"downloadPercentage" 
                      options:0
                      context:NULL];
    [fileDownload addObserver:self 
                   forKeyPath:@"finished" 
                      options:0
                      context:NULL];
    [fileDownload addObserver:self
                   forKeyPath:@"error"
                      options:0
                      context:NULL];
  }
}

@end
