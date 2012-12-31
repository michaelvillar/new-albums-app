//
//  MVAlbumsRequest.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVAlbumsRequest.h"
#import "MViTunesSearchRequest.h"
#import "MVArtist.h"
#import "MVAlbum.h"
#import "MVContextSource.h"

#define kMVAlbumsRequestLimit 500
#define kMVAlbumsRequestNbAlbumsPerArtist 2

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumsRequest () <MViTunesSearchRequestDelegate>

@property (strong, readwrite) NSSet *artistIds;
@property (strong, readwrite) NSDate *batchDate;
@property (readwrite) int batchesLeft;
@property (readwrite) BOOL completed;
@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSObject <MVContextSource> *contextSource;

- (void)complete;
- (int)nbBatches;
- (int)nbArtistsPerBatch;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumsRequest

@synthesize artistIds       = artistIds_,
            batchDate       = batchDate_,
            batchesLeft     = batchesLeft_,
            completed       = completed_,
            operationQueue  = operationQueue_,
            contextSource   = contextSource_,
            delegate        = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithArtistIds:(NSSet*)artistIds
         operationQueue:(NSOperationQueue*)operationQueue
          contextSource:(NSObject<MVContextSource>*)contextSource
{
  self = [super init];
  if(self)
  {
    artistIds_ = artistIds;
    batchDate_ = [NSDate date];
    batchesLeft_ = 0;
    completed_ = NO;
    operationQueue_ = operationQueue;
    contextSource_ = contextSource;
    delegate_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fetch
{
  if(self.artistIds.count == 0)
    return [self complete];
  MViTunesSearchRequest *request;
  NSArray *artistIds = self.artistIds.allObjects;
  int count = self.nbBatches;
  self.batchesLeft = count;
  for(int i=0;i<count;i++)
  {
    NSRange range = NSMakeRange(i*self.nbArtistsPerBatch, self.nbArtistsPerBatch);
    if(range.location + range.length > artistIds.count)
      range.length = artistIds.count - range.location;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    request = [[MViTunesSearchRequest alloc] init];
    request.country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    request.method = kMViTunesMethodLookup;
    request.ids = [[artistIds objectsAtIndexes:indexSet] componentsJoinedByString:@","];
    request.entity = kMViTunesEntityAlbum;
    request.limit = kMVAlbumsRequestNbAlbumsPerArtist;
    request.sort = kMViTunesSortRecent;
    request.delegate = self;
    request.operationQueue = self.operationQueue;
    [request search];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)complete
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if(self.completed)
      return;
    self.completed = YES;
    if([self.delegate respondsToSelector:@selector(albumsRequestDidFinish:)])
      [self.delegate albumsRequestDidFinish:self];
  });
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (int)nbBatches
{
  return ceil(((float)(self.artistIds.allObjects.count)) / self.nbArtistsPerBatch);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (int)nbArtistsPerBatch
{
  return floor(kMVAlbumsRequestLimit / (kMVAlbumsRequestNbAlbumsPerArtist + 1.0));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MViTunesSearchRequestDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)iTunesSearchRequest:(MViTunesSearchRequest *)request
             didFindResults:(NSArray *)results
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if(results.count > 0)
    {
      NSDictionary *albumDic;
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

      [self.contextSource.masterMoc performBlockAndWait:^{
        for(albumDic in results)
        {
          long long artistId = [[albumDic valueForKey:@"artistId"] longLongValue];
          NSNumber *artistNumberId = [NSNumber numberWithLongLong:artistId];
          long long albumId = [[albumDic valueForKey:@"collectionId"] longLongValue];
          NSNumber *albumNumberId = [NSNumber numberWithLongLong:albumId];
          MVAlbum *album = (MVAlbum*)[MVAlbum objectWithiTunesId:albumNumberId
                                                           inMoc:self.contextSource.masterMoc];
          if(!album)
          {
            NSString *name = [albumDic valueForKey:@"collectionName"];
            NSString *releaseDateString = [albumDic valueForKey:@"releaseDate"];
            NSDate *releaseDate = [dateFormatter dateFromString:releaseDateString];
            NSString *iTunesStoreUrl = [albumDic valueForKey:@"collectionViewUrl"];
            NSString *artworkUrl = [albumDic valueForKey:@"artworkUrl100"];

            album = [MVAlbum insertInManagedObjectContext:self.contextSource.masterMoc];
            album.createdAt = self.batchDate;
            album.name = name;
            album.iTunesIdValue = albumId;
            album.releaseDate = releaseDate;
            album.iTunesStoreUrl = iTunesStoreUrl;
            album.artworkUrl = artworkUrl;
            
            MVArtist *artist = (MVArtist*)[MVArtist objectWithiTunesId:artistNumberId
                                                                 inMoc:self.contextSource.masterMoc];
            if(!artist)
            {
              artist = [MVArtist insertInManagedObjectContext:self.contextSource.masterMoc];
              artist.iTunesIdValue = artistId;
              artist.name = [albumDic valueForKey:@"artistName"];
            }
            album.artist = artist;
          }
        }
      }];
    }
    
    self.batchesLeft--;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(albumsRequestDidFinish:didChangeProgression:)])
        [self.delegate albumsRequestDidFinish:self
                         didChangeProgression:MIN(self.artistIds.count,
                                                  (self.nbBatches - self.batchesLeft) *
                                                  self.nbArtistsPerBatch)];
    });
    
    if(self.batchesLeft == 0)
      [self complete];
  });
}

@end
