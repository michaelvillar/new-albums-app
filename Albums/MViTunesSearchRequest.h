//
//  MViTunesSearchRequest.h
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMViTunesMethodSearch @"search"
#define kMViTunesMethodLookup @"lookup"
#define kMViTunesEntityNone nil
#define kMViTunesEntityAlbum @"album"
#define kMViTunesEntityArtist @"musicArtist"
#define kMViTunesLimitNone -1
#define kMViTunesSortNone nil
#define kMViTunesSortRecent @"recent"

@class MViTunesSearchRequest;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MViTunesSearchRequestDelegate
- (void)iTunesSearchRequest:(MViTunesSearchRequest*)request
             didFindResults:(NSArray*)results;
- (void)iTunesSearchRequestDidFail:(MViTunesSearchRequest*)request;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MViTunesSearchRequest : NSObject

@property (copy, readwrite) NSString *country;
@property (copy, readwrite) NSString *method;
@property (copy, readwrite) NSString *term;
@property (copy, readwrite) NSString *ids;
@property (copy, readwrite) NSString *entity;
@property (readwrite) int limit;
@property (copy, readwrite) NSString *sort;
@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (weak, readwrite) NSObject<MViTunesSearchRequestDelegate> *delegate;

- (void)search;

@end
