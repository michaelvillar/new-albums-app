//
//  KOUFileDownload.h
//  URLKit
//
//  Created by Michael Villar on 4/23/12.
//  Copyright (c) 2012 Noaliasing. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVFileDownload;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol KOUFileDownloadDelegate
@optional
- (void)fileDownloadDidStart:(MVFileDownload*)fileDownload;
- (void)fileDownload:(MVFileDownload*)fileDownload
         didProgress:(float)percent;
- (void)fileDownloadDidFinish:(MVFileDownload*)fileDownload;
- (void)fileDownload:(MVFileDownload*)fileDownload
    didFailWithError:(NSError*)error;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFileDownload : NSObject

@property (strong, readonly) NSURL *sourceURL;
@property (strong, readonly) NSURL *destinationURL;
@property (readonly) float downloadPercentage;
@property (readonly, getter = isFinished) BOOL finished;
@property (readonly, getter = isError) BOOL error;
@property (strong, readonly) NSOperationQueue *operationQueue;
@property (weak, readwrite) NSObject <KOUFileDownloadDelegate> *delegate;

- (id)initWithSourceURL:(NSURL*)sourceURL
         destinationURL:(NSURL*)destinationURL
         operationQueue:(NSOperationQueue*)operationQueue;
- (void)start;

@end
