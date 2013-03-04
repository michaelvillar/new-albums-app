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
#import "NSString+Levenshtein.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVArtistIdsRequest () <MViTunesSearchRequestDelegate>

@property (strong, readwrite) NSSet *artistNames;
@property (strong, readwrite) NSString *countryCode;
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
            countryCode     = countryCode_,
            artistsFetchedCount = artistsFetchedCount_,
            completed       = completed_,
            operationQueue  = operationQueue_,
            contextSource   = contextSource_,
            delegate        = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithArtistNames:(NSSet*)artistNames
              countryCode:(NSString*)countryCode
           operationQueue:(NSOperationQueue*)operationQueue
            contextSource:(NSObject<MVContextSource>*)contextSource
{
  self = [super init];
  if(self)
  {
    artistNames_ = artistNames;
    countryCode_ = countryCode;
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
    request.country = self.countryCode;
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
- (void)iTunesSearchRequestDidFail:(MViTunesSearchRequest *)request
{
  if([self.delegate respondsToSelector:@selector(artistIdsRequestDidFail:)])
    [self.delegate artistIdsRequestDidFail:self];
}

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
      
      NSCharacterSet *letterSet = [[NSCharacterSet letterCharacterSet] invertedSet];
      
      NSData *data = [request.term dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
      NSString *string1 = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
      string1 = [[[string1 componentsSeparatedByCharactersInSet:letterSet]
                 componentsJoinedByString:@""] lowercaseString];

      data = [artistName dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
      NSString *string2 = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
      string2 = [[[string2 componentsSeparatedByCharactersInSet:letterSet]
                 componentsJoinedByString:@""] lowercaseString];
      
      int matchGain = 10;
      int cost = 1;
      NSUInteger score = [string1 compareWithWord:string2 matchGain:matchGain missingCost:cost] +
                         (MIN(string1.length, string2.length) * matchGain) -
                          abs(string1.length - string2.length) * cost;
      
      [self.contextSource performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        MVArtist *artist = (MVArtist*)[MVArtist objectWithiTunesId:artistNumberId
                                                             inMoc:moc];
        if(!artist)
        {
          artist = [MVArtist insertInManagedObjectContext:moc];
          artist.iTunesIdValue = (score == 0 ? artistId : -1);
          artist.name = artistName;
          artist.fetchAlbumsValue = (score == 0);
        }
        
        if(![artist.name isEqualToString:request.term])
        {
          MVArtistName *artistName = [MVArtistName insertInManagedObjectContext:moc];
          artistName.name = request.term;
          [artist addNamesObject:artistName];
        }
      }];
    }
    else
    {
      [self.contextSource performBlockAndWaitOnMasterMoc:^(NSManagedObjectContext *moc) {
        MVArtistName *artistName = [MVArtistName insertInManagedObjectContext:moc];
        artistName.name = request.term;
      }];
    }
    
    self.artistsFetchedCount++;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(artistIdsRequest:didChangeProgression:)])
        [self.delegate artistIdsRequest:self didChangeProgression:self.artistsFetchedCount];
    });
    
    if(self.artistsFetchedCount == self.artistNames.count)
    {
      [self complete];
    }
  });
}

@end
