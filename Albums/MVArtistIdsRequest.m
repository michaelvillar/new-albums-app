//
//  MVArtistIdsRequest.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVArtistIdsRequest.h"
#import "MViTunesSearchRequest.h"
#import "MVArtist.h"
#import "MVArtistName.h"
#import "MVContextSource.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVArtistIdsRequest () <MViTunesSearchRequestDelegate>

@property (strong, readwrite) NSSet *artistNames;
@property (readwrite) int artistsFetchedCount;
@property (readwrite) BOOL completed;
@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSObject <MVContextSource> *contextSource;

- (void)complete;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVArtistIdsRequest

@synthesize artistNames     = artistNames_,
            artistsFetchedCount = artistsFetchedCount_,
            completed       = completed_,
            operationQueue  = operationQueue_,
            contextSource   = contextSource_,
            delegate        = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithArtistNames:(NSSet*)artistNames
           operationQueue:(NSOperationQueue*)operationQueue
            contextSource:(NSObject<MVContextSource>*)contextSource
{
  self = [super init];
  if(self)
  {
    artistNames_ = artistNames;
    artistsFetchedCount_ = 0;
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
  if(self.artistNames.count == 0)
    return [self complete];
  MViTunesSearchRequest *request;
  NSString *artistName;
  for(artistName in self.artistNames)
  {
    request = [[MViTunesSearchRequest alloc] init];
    request.country = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    request.term = artistName;
    request.entity = kMViTunesEntityArtist;
    request.limit = 1;
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
    if([self.delegate respondsToSelector:@selector(artistIdsRequestDidFinish:)])
      [self.delegate artistIdsRequestDidFinish:self];
  });
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
      NSDictionary *firstResult = [results objectAtIndex:0];
      NSString *artistName = [firstResult valueForKey:@"artistName"];
      long long artistId = [[firstResult valueForKey:@"artistId"] longLongValue];
      NSNumber *artistNumberId = [NSNumber numberWithLongLong:artistId];
      
      [self.contextSource.masterMoc performBlockAndWait:^{
        MVArtist *artist = (MVArtist*)[MVArtist objectWithiTunesId:artistNumberId
                                                             inMoc:self.contextSource.masterMoc];
        if(!artist)
        {
          artist = [MVArtist insertInManagedObjectContext:self.contextSource.masterMoc];
          artist.iTunesIdValue = artistId;
          artist.name = artistName;
          artist.fetchAlbumsValue = YES;
        }
        
        if(![artist.name isEqualToString:request.term])
        {
          MVArtistName *artistName = [MVArtistName insertInManagedObjectContext:
                                      self.contextSource.masterMoc];
          artistName.name = request.term;
          [artist addNamesObject:artistName];
        }
      }];
    }
    else
    {
      [self.contextSource.masterMoc performBlockAndWait:^{
        MVArtistName *artistName = [MVArtistName insertInManagedObjectContext:
                                    self.contextSource.masterMoc];
        artistName.name = request.term;
      }];
    }
    
    self.artistsFetchedCount++;
    if(self.artistsFetchedCount == self.artistNames.count)
    {
      [self complete];
    }
  });
}

@end
