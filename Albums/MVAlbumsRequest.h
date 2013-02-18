//
//  MVAlbumsRequest.h
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVAlbumsRequest;
@protocol MVContextSource;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MVAlbumsRequestDelegate
- (void)albumsRequestDidFinish:(MVAlbumsRequest*)request
          didChangeProgression:(int)nbFetchedArtists;
- (void)albumsRequestDidFinish:(MVAlbumsRequest*)request;
- (void)albumsRequestDidFail:(MVAlbumsRequest*)request;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumsRequest : NSObject

@property (strong, readonly) NSSet *artistIds;
@property (strong, readonly) NSString *countryCode;
@property (weak, readwrite) NSObject <MVAlbumsRequestDelegate> *delegate;

- (id)initWithArtistIds:(NSSet*)artistIds
            countryCode:(NSString*)countryCode
         operationQueue:(NSOperationQueue*)operationQueue
          contextSource:(NSObject<MVContextSource>*)contextSource;
- (void)fetch;

@end
