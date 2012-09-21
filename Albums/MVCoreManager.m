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
#import "MVCoreManager+CoreData.h"
#import "MVArtist.h"
#import "MVArtistName.h"
#import "MVAlbum.h"
#import "MVArtistIdsRequest.h"
#import "MVAlbumsRequest.h"

#define kMVCoreManagerStepIdle 0
#define kMVCoreManagerStepSearchingArtistIds 1
#define kMVCoreManagerStepSearchingNewAlbums 2

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreManager () <MVArtistIdsRequestDelegate,
                             MVAlbumsRequestDelegate>

@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) MVArtistIdsRequest *artistIdsRequest;
@property (strong, readwrite) MVAlbumsRequest *albumsRequest;
@property (readwrite) int step;

- (NSSet*)getArtistNamesFromiPod;
- (void)searchAlbums;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCoreManager

@synthesize operationQueue        = operationQueue_,
            artistIdsRequest      = artistIdsRequest_,
            albumsRequest         = albumsRequest_,
            step                  = step_,
            masterMoc             = masterMoc_,
            uiMoc                 = uiMoc_;

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
    masterMoc_ = nil;
    uiMoc_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sync
{
  if(self.step != kMVCoreManagerStepIdle)
    return;
  [self.operationQueue addOperationWithBlock:^{
    self.step = kMVCoreManagerStepSearchingArtistIds;
    NSSet *artistNames = [self getArtistNamesFromiPod];
    NSMutableSet *toFetchArtistNames = [NSMutableSet set];
    [self.masterMoc performBlockAndWait:^{
      NSString *artistName;
      for(artistName in artistNames)
      {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"name = %@ || ANY names.name = %@",
                                  artistName, artistName];
        NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVArtist entityName]];
        req.predicate = predicate;
        NSArray *results = [self.masterMoc executeFetchRequest:req error:nil];
        if(results.count == 0)
        {
          predicate = [NSPredicate predicateWithFormat:@"name = %@", artistName];
          req = [[NSFetchRequest alloc] initWithEntityName:[MVArtistName entityName]];
          req.predicate = predicate;
          results = [self.masterMoc executeFetchRequest:req error:nil];
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
  NSMutableSet *artistIds = [NSMutableSet set];
  NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVArtist entityName]];
  req.predicate = [NSPredicate predicateWithFormat:@"fetchAlbums = YES"];
  [self.masterMoc performBlockAndWait:^{
    NSArray *results = [self.masterMoc executeFetchRequest:req error:nil];
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
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVContextSource Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)masterMoc
{
  if (masterMoc_==nil)
    masterMoc_ = [self setupMasterMoc];
  
  return masterMoc_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)uiMoc
{
  if (uiMoc_==nil)
    uiMoc_ = [self setupUIMocWithMasterMoc:self.masterMoc];
  
  return uiMoc_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSSet*)getArtistNamesFromiPod
{
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
- (void)artistIdsRequestDidFinish:(MVArtistIdsRequest *)request
{
  NSLog(@"artistIdsRequestDidFinish");
  [self.masterMoc performBlock:^{
    [self.masterMoc mv_save];
  }];
  [self searchAlbums];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVAlbumsRequestDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumsRequestDidFinish:(MVAlbumsRequest *)request
{
  NSLog(@"albumsRequestDidFinish");
  [self.masterMoc performBlock:^{
    [self.masterMoc mv_save];
  }];
}

@end
