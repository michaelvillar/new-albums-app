//
//  MViTunesSearchManager.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "MVCoreManager.h"
#import "MViTunesSearchRequest.h"
#import "MVArtist.h"
#import "MVArtistName.h"
#import "MVAlbum.h"
#import "MVOption.h"
#import "MVArtistIdsRequest.h"
#import "MVAlbumsRequest.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreManager () <MVArtistIdsRequestDelegate,
                             MVAlbumsRequestDelegate>

@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) MVArtistIdsRequest *artistIdsRequest;
@property (strong, readwrite) MVAlbumsRequest *albumsRequest;
@property (readwrite) int step;
@property (readwrite) float stepProgression;
@property (readwrite, getter = isSyncing) BOOL syncing;
@property (strong, readwrite) NSSet *iPodArtistAlbumNames;

- (NSSet*)getArtistNamesFromiPod;
- (NSSet*)getArtistAlbumNamesFromiPod;
- (void)markOwnedAlbumsAsHidden;
- (void)searchAlbums;
- (void)syncDidFail;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCoreManager

@synthesize countryCode           = countryCode_,
            operationQueue        = operationQueue_,
            artistIdsRequest      = artistIdsRequest_,
            albumsRequest         = albumsRequest_,
            step                  = step_,
            stepProgression       = stepProgression_,
            uiMoc                 = uiMoc_,
            syncing               = syncing_,
            iPodArtistAlbumNames  = iPodArtistAlbumNames_,
            delegate              = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    countryCode_ = nil;
    operationQueue_ = [[NSOperationQueue alloc] init];
    operationQueue_.maxConcurrentOperationCount = 20;
    artistIdsRequest_ = nil;
    albumsRequest_ = nil;
    step_ = kMVCoreManagerStepIdle;
    uiMoc_ = nil;
    syncing_ = NO;
    iPodArtistAlbumNames_ = [self getArtistAlbumNamesFromiPod];
    delegate_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sync
{
  if(self.step != kMVCoreManagerStepIdle)
    return;
  self.step = kMVCoreManagerStepWaitToSync;
  [self.operationQueue addOperationWithBlock:^{
    __block NSString *lastSyncDateString;
    __block NSString *lastSyncCountryString;
    [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
      MVOption *lastSyncDateOption = [MVOption optionWithKey:kMVOptionKeyLastSyncDate
                                                       inMoc:moc];
      lastSyncDateString = lastSyncDateOption.value.copy;
      
      MVOption *lastSyncCountryOption = [MVOption optionWithKey:kMVOptionKeyLastSyncCountry
                                                          inMoc:moc];
      lastSyncCountryString = lastSyncCountryOption.value.copy;
    }];
    if(lastSyncDateString &&
       lastSyncCountryString &&
       [self.countryCode isEqualToString:lastSyncCountryString])
    {
      double lastSyncDateDouble = lastSyncDateString.doubleValue;
      NSDate *lastSyncDate = [NSDate dateWithTimeIntervalSince1970:lastSyncDateDouble];
      if([[NSDate date] timeIntervalSinceDate:lastSyncDate] < 24 * 3600) {
        self.step = kMVCoreManagerStepIdle;
        return;
      }
    }
    
    if(![self.countryCode isEqualToString:lastSyncCountryString])
    {
      // delete all albums
      [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVAlbum entityName]];
        NSArray *albums = [moc executeFetchRequest:req error:nil];
        for(MVAlbum *album in albums) {
          [moc deleteObject:album];
        }
      }];
    }
    
    self.syncing = YES;
    self.step = kMVCoreManagerStepSearchingArtistIds;
    self.stepProgression = 0.0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(coreManagerDidStartSync:)])
        [self.delegate coreManagerDidStartSync:self];
    });
    
    NSSet *artistNames = [self getArtistNamesFromiPod];
    NSMutableSet *toFetchArtistNames = [NSMutableSet set];
    [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
      NSString *artistName;
      for(artistName in artistNames)
      {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"name = %@ || ANY names.name = %@",
                                  artistName, artistName];
        NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVArtist entityName]];
        req.predicate = predicate;
        NSArray *results = [moc executeFetchRequest:req error:nil];
        if(results.count == 0)
        {
          predicate = [NSPredicate predicateWithFormat:@"name = %@", artistName];
          req = [[NSFetchRequest alloc] initWithEntityName:[MVArtistName entityName]];
          req.predicate = predicate;
          results = [moc executeFetchRequest:req error:nil];
          if(results.count == 0)
          {
            [toFetchArtistNames addObject:artistName];
          }
        }
      }
    }];
    self.artistIdsRequest = [[MVArtistIdsRequest alloc] initWithArtistNames:toFetchArtistNames
                                                                countryCode:self.countryCode
                                                             operationQueue:self.operationQueue
                                                              contextSource:self];
    self.artistIdsRequest.delegate = self;
    [self.artistIdsRequest fetch];
  }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Sync Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)searchAlbums
{
  self.step = kMVCoreManagerStepSearchingNewAlbums;
  self.stepProgression = 0.0;
  
  NSMutableSet *artistIds = [NSMutableSet set];
  NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVArtist entityName]];
  req.predicate = [NSPredicate predicateWithFormat:@"fetchAlbums = YES"];
  [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
    NSArray *results = [moc executeFetchRequest:req error:nil];
    MVArtist *artist;
    for(artist in results)
    {
      [artistIds addObject:artist.iTunesId.stringValue];
    }
  }];
  self.albumsRequest = [[MVAlbumsRequest alloc] initWithArtistIds:artistIds
                                                      countryCode:self.countryCode
                                                   operationQueue:self.operationQueue
                                                    contextSource:self];
  self.albumsRequest.delegate = self;
  [self.albumsRequest fetch];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)syncDidFail
{
  self.syncing = NO;
  self.step = kMVCoreManagerStepIdle;
  self.stepProgression = 0.0;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(coreManagerDidFailToSync:)])
      [self.delegate coreManagerDidFailToSync:self];
  });
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVContextSource Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)uiMoc
{
  if (uiMoc_==nil)
    uiMoc_ = [[MVCoreDataFactory sharedInstance] createMOC];
  
  return uiMoc_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext*)createDraftMoc
{
  return [[MVCoreDataFactory sharedInstance] createDraftMOC];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)performBlockAndWaitOnMasterMoc:(void (^)(NSManagedObjectContext* moc))block
{
  [[MVCoreDataFactory sharedInstance] performBlockAndWaitOnMasterMoc:block];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSSet*)getArtistNamesFromiPod
{
//  return [NSArray arrayWithObjects:@"Air",@"Angus & Julia Stone",@"Archive",@"Bang gang",@"Black Eyed Peas",@"Blink 182",@"Calvin Harris",@"Coldplay",@"Cut Copy",@"Daft Punk",@"Darwin Deez",@"David Guetta",@"Death Cab For Cutie", nil];
  NSMutableSet *artistNames = [NSMutableSet set];
  MPMediaQuery *query = [MPMediaQuery artistsQuery];
  NSArray *artists = [query collections];
  MPMediaItemCollection *collection;
  NSString *name;
  for(collection in artists)
  {
    MPMediaItem *item = [collection representativeItem];
    name = [item valueForProperty:MPMediaItemPropertyArtist];
    if(![artistNames containsObject:name])
      [artistNames addObject:name];
  }
  return artistNames;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSSet*)getArtistAlbumNamesFromiPod
{
  NSMutableSet *albumNames = [NSMutableSet set];
  MPMediaQuery *query = [MPMediaQuery albumsQuery];
  NSArray *albums = [query collections];
  MPMediaItemCollection *collection;
  NSString *name;
  for(collection in albums)
  {
    MPMediaItem *item = [collection representativeItem];
    name = [NSString stringWithFormat:@"%@ - %@",
            [item valueForProperty:MPMediaItemPropertyArtist],
            [item valueForProperty:MPMediaItemPropertyAlbumTitle]];
    if(![albumNames containsObject:name])
      [albumNames addObject:name];
  }
  return albumNames;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)markOwnedAlbumsAsHidden
{
  __block MVCoreManager *weakSelf = self;
  [self.operationQueue addOperationWithBlock:^{
    [weakSelf performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
      NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVAlbum entityName]];
      req.predicate = [NSPredicate predicateWithFormat:@"hidden = %d",NO];
      NSArray *albums = [moc executeFetchRequest:req error:nil];
      for(MVAlbum *album in albums) {
        NSString *name = [NSString stringWithFormat:
                          @"%@ - %@",
                          album.artist.name, album.name];
        if([weakSelf.iPodArtistAlbumNames containsObject:name]) {
          album.hiddenValue = YES;
        }
      }
      
      [weakSelf performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        MVOption *lastSyncDateOption = [MVOption optionWithKey:kMVOptionKeyLastSyncDate
                                                         inMoc:moc];
        lastSyncDateOption.value = [NSString stringWithFormat:@"%f",
                                    [[NSDate date] timeIntervalSince1970]];
        
        MVOption *lastSyncCountry = [MVOption optionWithKey:kMVOptionKeyLastSyncCountry
                                                      inMoc:moc];
        lastSyncCountry.value = weakSelf.countryCode;
        
        [moc mv_save];
      }];
      
      weakSelf.syncing = NO;
      weakSelf.step = kMVCoreManagerStepIdle;
      weakSelf.stepProgression = 0.0;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if([weakSelf.delegate respondsToSelector:@selector(coreManagerDidFinishSync:)])
          [weakSelf.delegate coreManagerDidFinishSync:weakSelf];
        weakSelf = nil;
      });
    }];
  }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVArtistIdsRequestDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)artistIdsRequest:(MVArtistIdsRequest*)request
    didChangeProgression:(int)nbFetchedArtists
{
  if(self.step == kMVCoreManagerStepSearchingArtistIds)
    self.stepProgression = ((float)nbFetchedArtists) / ((float)(request.artistNames.count));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)artistIdsRequestDidFinish:(MVArtistIdsRequest *)request
{
  self.stepProgression = 1.0;
  
  NSLog(@"artistIdsRequestDidFinish");
  [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
    [moc mv_save];
  }];
    
  [self searchAlbums];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)artistIdsRequestDidFail:(MVArtistIdsRequest *)request
{
  [self syncDidFail];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVAlbumsRequestDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumsRequestDidFinish:(MVAlbumsRequest*)request
          didChangeProgression:(int)nbFetchedArtists
{
  if(self.step == kMVCoreManagerStepSearchingNewAlbums)
    self.stepProgression = ((float)nbFetchedArtists) / ((float)(request.artistIds.count));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumsRequestDidFinish:(MVAlbumsRequest *)request
{
  self.stepProgression = 1.0;
  
  NSLog(@"albumsRequestDidFinish");  
  [self markOwnedAlbumsAsHidden];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumsRequestDidFail:(MVAlbumsRequest *)request
{
  [self syncDidFail];
}

@end
