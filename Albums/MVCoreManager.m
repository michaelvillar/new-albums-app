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

- (NSSet*)getArtistNamesFromiPod;
- (void)searchAlbums;
- (void)syncDidFail;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCoreManager

@synthesize operationQueue        = operationQueue_,
            artistIdsRequest      = artistIdsRequest_,
            albumsRequest         = albumsRequest_,
            step                  = step_,
            stepProgression       = stepProgression_,
            uiMoc                 = uiMoc_,
            syncing               = syncing_,
            delegate              = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    operationQueue_ = [[NSOperationQueue alloc] init];
    operationQueue_.maxConcurrentOperationCount = 20;
    artistIdsRequest_ = nil;
    albumsRequest_ = nil;
    step_ = kMVCoreManagerStepIdle;
    uiMoc_ = nil;
    syncing_ = NO;
    delegate_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sync
{
  if(self.step != kMVCoreManagerStepIdle)
    return;
  [self.operationQueue addOperationWithBlock:^{
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
  return [NSArray arrayWithObjects:@"Air",@"Angus & Julia Stone",@"Archive",@"Bang gang",@"Black Eyed Peas",@"Blink 182",@"Calvin Harris",@"Coldplay",@"Cut Copy",@"Daft Punk",@"Darwin Deez",@"David Guetta",@"Death Cab For Cutie", nil];
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
  [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
    [moc mv_save];
  }];
  
  self.syncing = NO;
  self.step = kMVCoreManagerStepIdle;
  self.stepProgression = 0.0;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(coreManagerDidFinishSync:)])
      [self.delegate coreManagerDidFinishSync:self];
  });
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumsRequestDidFail:(MVAlbumsRequest *)request
{
  [self syncDidFail];
}

@end
