//
//  KOUFileDownload.m
//  URLKit
//
//  Created by Michael Villar on 4/23/12.
//  Copyright (c) 2012 Noaliasing. All rights reserved.
//

#import "MVFileDownload.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFileDownload () <NSURLConnectionDelegate>

@property (strong, readwrite) NSURL *sourceURL;
@property (strong, readwrite) NSURL *destinationURL;
@property (readwrite) float downloadPercentage;
@property (readwrite, getter = isFinished) BOOL finished;
@property (readwrite, getter = isError) BOOL error;
@property (strong, readwrite) NSOperationQueue *operationQueue;
@property (strong, readwrite) NSURLConnection *urlConnection;
@property (strong, readwrite) NSMutableData *mutableData;
@property (readwrite) NSInteger statusCode;
@property (readwrite) long long expectedContentLength;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVFileDownload

@synthesize sourceURL             = sourceURL_,
            destinationURL        = destinationURL_,
            downloadPercentage    = downloadPercentage_,
            finished              = finished_,
            error                 = error_,
            operationQueue        = operationQueue_,
            urlConnection         = urlConnection_,
            mutableData           = mutableData_,
            statusCode            = statusCode_,
            expectedContentLength = expectedContentLength_,
            delegate              = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithSourceURL:(NSURL*)sourceURL
         destinationURL:(NSURL*)destinationURL
         operationQueue:(NSOperationQueue*)operationQueue 
{
  self = [super init];
  if(self)
  {
    sourceURL_ = sourceURL;
    destinationURL_ = destinationURL;
    downloadPercentage_ = 0;
    finished_ = NO;
    error_ = NO;
    operationQueue_ = operationQueue;
    urlConnection_ = nil;
    mutableData_ = nil;
    statusCode_ = -1;
    expectedContentLength_ = -1;
    delegate_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)start
{
  NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		/*
		 * Init URL connection and start downloading the file
		 */
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.sourceURL];
		[req setHTTPMethod:@"GET"];
		
		self.mutableData = [NSMutableData data];
		self.urlConnection = [NSURLConnection connectionWithRequest:req 
                                                       delegate:self];
		if (!self.urlConnection) 
    {
			dispatch_async(dispatch_get_main_queue(), ^{
        if([self.delegate respondsToSelector:@selector(fileDownload:didFailWithError:)])
          [self.delegate fileDownload:self didFailWithError:nil];
      });
		}
		else 
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        if([self.delegate respondsToSelector:@selector(fileDownloadDidStart:)])
          [self.delegate fileDownloadDidStart:self];
      });
			CFRunLoopRun();
		}
	}];
	[self.operationQueue addOperation:operation];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileDownload:didFailWithError:)])
      [self.delegate fileDownload:self didFailWithError:nil];
    self.error = YES;
  });
	CFRunLoopStop(CFRunLoopGetCurrent());
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	[self.mutableData appendData:data];
  float percent = (100*(float)self.mutableData.length/self.expectedContentLength);
  self.downloadPercentage = percent;
  dispatch_async(dispatch_get_main_queue(), ^{
    if([self.delegate respondsToSelector:@selector(fileDownload:didProgress:)])
      [self.delegate fileDownload:self didProgress:percent];
  });
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
	self.statusCode = [httpResponse statusCode];
	self.expectedContentLength = [response expectedContentLength];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
  if(self.statusCode == 200)
  {
    NSString *destinationDirectory = [[self.destinationURL path] stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:destinationDirectory
           withIntermediateDirectories:YES 
                            attributes:nil 
                                 error:nil];
    [self.mutableData writeToURL:self.destinationURL 
                      atomically:YES];
    
    if(self.downloadPercentage != 100)
    {
      self.downloadPercentage = 100;
    }
    
    self.finished = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(fileDownloadDidFinish:)])
        [self.delegate fileDownloadDidFinish:self];
    });
  }
	else 
  {
    NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:
                                               @"StatusCode (%i) should be %i",
                                               self.statusCode,
                                               200]
                                         code:self.statusCode 
                                     userInfo:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      if([self.delegate respondsToSelector:@selector(fileDownload:didFailWithError:)])
        [self.delegate fileDownload:self didFailWithError:error];
      self.error = YES;
    });
  }
	CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
