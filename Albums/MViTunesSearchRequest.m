//
//  MViTunesSearchRequest.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MViTunesSearchRequest.h"
#import "MVJSONGetRequest.h"
#import "NSString+Escaping.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MViTunesSearchRequest ()
@property (readwrite) BOOL searched;
@property (strong, readwrite) MVJSONGetRequest *request;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MViTunesSearchRequest

@synthesize country         = country_,
            method          = method_,
            term            = term_,
            ids             = ids_,
            entity          = entity_,
            limit           = limit_,
            sort            = sort_,
            operationQueue  = operationQueue_,
            delegate        = delegate_,
            searched        = searched_,
            request         = request_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    country_ = @"US";
    method_ = kMViTunesMethodSearch;
    term_ = nil;
    ids_ = nil;
    entity_ = kMViTunesEntityNone;
    limit_ = kMViTunesLimitNone;
    sort_ = kMViTunesSortNone;
    operationQueue_ = nil;
    delegate_ = nil;
    searched_ = NO;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)search
{
  if(self.searched)
    return;
  self.searched = YES;
  
  NSMutableArray *args = [NSMutableArray array];
  if(self.country)
    [args addObject:[NSString stringWithFormat:@"country=%@",self.country.escapedString]];
  if(self.term)
    [args addObject:[NSString stringWithFormat:@"term=%@",self.term.escapedString]];
  if(self.ids)
    [args addObject:[NSString stringWithFormat:@"id=%@",self.ids]];
  if(self.entity != kMViTunesEntityNone)
    [args addObject:[NSString stringWithFormat:@"entity=%@",self.entity.escapedString]];
  if(self.limit != kMViTunesLimitNone)
    [args addObject:[NSString stringWithFormat:@"limit=%i",self.limit]];
  if(self.sort != kMViTunesSortNone)
    [args addObject:[NSString stringWithFormat:@"sort=%@",self.sort.escapedString]];
  
  NSString *query = [args componentsJoinedByString:@"&"];
  NSString *urlString = [[NSString alloc] initWithFormat:@"http://itunes.apple.com/%@?%@",
                                                         self.method, query];
  NSURL *url = [[NSURL alloc] initWithString:urlString];

  self.request = [[MVJSONGetRequest alloc] initWithURL:url];
  self.request.operationQueue = self.operationQueue;
  [self.request get:^(NSObject *json) {
    @try
    {
      if(json && [json isKindOfClass:[NSDictionary class]])
      {
        NSDictionary *dic = (NSDictionary*)json;
        NSArray *results = [dic valueForKey:@"results"];
        NSString *wrapperType = nil;
        if([self.entity isEqualToString:kMViTunesEntityArtist])
          wrapperType = @"artist";
        else if([self.entity isEqualToString:kMViTunesEntityAlbum])
          wrapperType = @"collection";
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:
                                        @"wrapperType = %@",
                                        wrapperType];
        results = [results filteredArrayUsingPredicate:filterPredicate];
        dispatch_async(dispatch_get_main_queue(), ^{
          if([self.delegate respondsToSelector:@selector(iTunesSearchRequest:didFindResults:)])
            [self.delegate iTunesSearchRequest:self didFindResults:results];
        });
      }
      else
      {
        dispatch_async(dispatch_get_main_queue(), ^{
          if ([self.delegate respondsToSelector:@selector(iTunesSearchRequestDidFail:)])
            [self.delegate iTunesSearchRequestDidFail:self];
        });
      }
    }
    @catch (NSException *exception)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(iTunesSearchRequestDidFail:)])
          [self.delegate iTunesSearchRequestDidFail:self];
      });
      NSLog(@"%@",exception);
      NSLog(@"%@",exception.callStackSymbols);
    }
  }];
}

@end
