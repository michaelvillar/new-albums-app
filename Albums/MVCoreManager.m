//
//  MViTunesSearchManager.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <TargetConditionals.h>
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
@property (strong, readwrite) NSSet *iPodArtistNames;

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
            iPodArtistNames       = iPodArtistNames_,
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
    iPodArtistAlbumNames_ = nil;
    iPodArtistNames_ = nil;
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
    __block NSString *lastSyncArtistsHash;
    
    BOOL forceSync = NO;
    if(!self.iPodArtistNames)
      self.iPodArtistNames = [self getArtistNamesFromiPod];
    NSString *artistsHash = [NSString stringWithFormat:@"%lu",
                             (unsigned long)self.iPodArtistNames.description.hash];
    
    if(!forceSync)
    {
      [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        MVOption *lastSyncDateOption = [MVOption optionWithKey:kMVOptionKeyLastSyncDate
                                                         inMoc:moc];
        lastSyncDateString = lastSyncDateOption.value.copy;
        
        MVOption *lastSyncCountryOption = [MVOption optionWithKey:kMVOptionKeyLastSyncCountry
                                                            inMoc:moc];
        lastSyncCountryString = lastSyncCountryOption.value.copy;
        
        MVOption *lastSyncArtistsHashOption = [MVOption optionWithKey:kMVOptionKeyLastSyncArtistsHash
                                                                inMoc:moc];
        lastSyncArtistsHash = lastSyncArtistsHashOption.value.copy;
      }];
      
      if(!lastSyncArtistsHash ||
         ![lastSyncArtistsHash isEqualToString:artistsHash])
      {
        // sync no matter what because artists have changed
      }
      else if(lastSyncDateString &&
              lastSyncCountryString &&
              [self.countryCode isEqualToString:lastSyncCountryString])
      {
        double lastSyncDateDouble = lastSyncDateString.doubleValue;
        NSDate *lastSyncDate = [NSDate dateWithTimeIntervalSince1970:lastSyncDateDouble];
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDateComponents *components = [gregorian components:NSYearCalendarUnit |
                                        NSMonthCalendarUnit |  NSDayCalendarUnit
                                                    fromDate:[NSDate date]];
        [components setHour:10];
        NSDate *todayAt10AMGMT = [gregorian dateFromComponents:components];
        NSDate *newAlbumsReleasedDate = ([[NSDate date] timeIntervalSinceDate:todayAt10AMGMT] > 0 ?
                                         todayAt10AMGMT :
                                         [todayAt10AMGMT dateByAddingTimeInterval:- 24 * 3600]);
        if([newAlbumsReleasedDate timeIntervalSinceDate:lastSyncDate] < 0) {
          self.step = kMVCoreManagerStepIdle;
          return;
        }
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
    
    NSSet *artistNames = self.iPodArtistNames;
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
#pragma mark Public Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasSyncedAtLeastOnce
{
  __block BOOL syncedAtLeastOnce = NO;
  [self performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
    MVOption *lastSyncDateOption = [MVOption optionWithKey:kMVOptionKeyLastSyncDate
                                                     inMoc:moc];
    syncedAtLeastOnce = lastSyncDateOption.value != nil;
  }];
  return syncedAtLeastOnce;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (float)progression
{
  if(self.step == kMVCoreManagerStepIdle)
    return 1.0;
  else if(self.step == kMVCoreManagerStepSearchingArtistIds)
    return self.stepProgression * 0.5;
  else if(self.step == kMVCoreManagerStepSearchingNewAlbums)
    return 0.5 + self.stepProgression * 0.4;
  else if(self.step == kMVCoreManagerStepHidingOwnedAlbums)
    return 0.9 + self.stepProgression * 0.1;
  return 0.0;
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
  #if TARGET_IPHONE_SIMULATOR
  return [NSArray arrayWithObjects:@"Air",@"Angus & Julia Stone",@"Archive",
          @"Bang gang",@"Black Eyed Peas",@"Blink 182",@"Calvin Harris",
          @"Coldplay",@"Cut Copy",@"Daft Punk",@"Darwin Deez",@"David Guetta",
          @"Death Cab For Cutie", nil];
  #endif
  NSMutableSet *artistNames = [NSMutableSet set];
  NSArray *albumCollections = [[MPMediaQuery albumsQuery] collections];
  MPMediaItemCollection *albumCollection;
  for(albumCollection in albumCollections)
  {
    NSArray *albumSongs = [albumCollection items];
    NSUInteger albumSongsCount = albumSongs.count;
    NSMutableDictionary *artistCountInAlbum = [NSMutableDictionary dictionary];
    for(MPMediaItem *albumSong in albumSongs)
    {
      NSString *artistName = [albumSong valueForProperty:MPMediaItemPropertyArtist];
      NSMutableArray *countArr = [artistCountInAlbum valueForKey:artistName];
      if(countArr)
        [countArr addObject:@""];
      else {
        countArr = [NSMutableArray array];
        [artistCountInAlbum setValue:countArr
                              forKey:artistName];
      }
    }
    for(NSString *artistName in artistCountInAlbum.allKeys)
    {
      NSArray *countArr = [artistCountInAlbum valueForKey:artistName];
      NSUInteger count = countArr.count;
      if(count &&
         ((((float)(count)) / albumSongsCount) >= 0.5 || albumSongsCount == 1) &&
         ![artistName isEqualToString:@"Various Artists"])
      {
        [artistNames addObject:artistName];
      }
    }
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
    MPMediaItem *item = collection.representativeItem;
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
  self.step = kMVCoreManagerStepHidingOwnedAlbums;
  self.stepProgression = 0.0;
  
  __block MVCoreManager *weakSelf = self;
  [self.operationQueue addOperationWithBlock:^{
    if(!weakSelf.iPodArtistAlbumNames)
      weakSelf.iPodArtistAlbumNames = [self getArtistAlbumNamesFromiPod];
    
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
      
      weakSelf.stepProgression = 0.5;
      
      BOOL wasSyncedAtLeastOnce = self.hasSyncedAtLeastOnce;
      if(!wasSyncedAtLeastOnce)
        [self willChangeValueForKey:@"syncedAtLeastOnce"];
      
      [weakSelf performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        MVOption *lastSyncDateOption = [MVOption optionWithKey:kMVOptionKeyLastSyncDate
                                                         inMoc:moc];
        lastSyncDateOption.value = [NSString stringWithFormat:@"%f",
                                    [[NSDate date] timeIntervalSince1970]];
        
        MVOption *lastSyncCountry = [MVOption optionWithKey:kMVOptionKeyLastSyncCountry
                                                      inMoc:moc];
        lastSyncCountry.value = weakSelf.countryCode;
        
        MVOption *lastSyncArtistsHash = [MVOption optionWithKey:kMVOptionKeyLastSyncArtistsHash
                                                          inMoc:moc];
        lastSyncArtistsHash.value = [NSString stringWithFormat:@"%lu",
                                     (unsigned long)weakSelf.iPodArtistNames.description.hash];
        
        [moc mv_save];
      }];
      
      if(!wasSyncedAtLeastOnce)
        [self didChangeValueForKey:@"syncedAtLeastOnce"];
      
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
