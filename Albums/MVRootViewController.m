//
//  MVRootViewController.m
//  Albums
//
//  Created by Michaël on 10/10/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVRootViewController.h"
#import "MVContextSource.h"
#import "MVCoreManager.h"
#import "MVAlbumsViewController.h"
#import "MVFirstSyncViewController.h"

#define kMVRatio 800
#define kMVDuration 0.2

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVRootViewController () <UIGestureRecognizerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;
@property (strong, readwrite) MVAlbumsViewController *albumsViewController;
@property (strong, readwrite, nonatomic) MVFirstSyncViewController *firstSyncViewController;
@property (strong, readwrite) UIView *mainView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVRootViewController

@synthesize coreManager               = coreManager_,
            contextSource             = contextSource_,
            albumsViewController      = albumsViewController_,
            firstSyncViewController   = firstSyncViewController_,
            mainView                  = mainView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
{
  self = [super init];
  if (self)
  {
    contextSource_ = contextSource;
    coreManager_ = coreManager;
    albumsViewController_ = [[MVAlbumsViewController alloc] initWithContextSource:contextSource
                                                                      coreManager:coreManager];
    firstSyncViewController_ = nil;
    mainView_ = nil;
    
    [coreManager_ addObserver:self forKeyPath:@"syncedAtLeastOnce" options:0 context:NULL];
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [coreManager_ removeObserver:self forKeyPath:@"syncedAtLeastOnce"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
  if(!self.mainView)
  {
    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                             self.view.frame.size.width,
                                                             self.view.frame.size.height)];
    [self.view addSubview:self.mainView];
  }
  
  if(self.coreManager.hasSyncedAtLeastOnce)
  {
    self.albumsViewController.view.frame = self.mainView.bounds;
    [self.mainView addSubview:self.albumsViewController.view];
  }
  else
  {
    self.firstSyncViewController.view.frame = self.mainView.bounds;
    [self.mainView addSubview:self.firstSyncViewController.view];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload
{
  [self.albumsViewController.view removeFromSuperview];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (MVFirstSyncViewController*)firstSyncViewController
{
  if(!firstSyncViewController_)
  {
    firstSyncViewController_ = [[MVFirstSyncViewController alloc]
                                initWithContextSource:self.contextSource
                                coreManager:self.coreManager];
  }
  return firstSyncViewController_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KVO

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
  if(object == self.coreManager)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      if(self.coreManager.hasSyncedAtLeastOnce) {
        self.albumsViewController.view.frame = self.mainView.bounds;
        [self.mainView insertSubview:self.albumsViewController.view
                        belowSubview:self.firstSyncViewController.view];
        
        [UIView animateWithDuration:0.25 animations:^{
          self.firstSyncViewController.view.alpha = 0.0;
        } completion:^(BOOL finished) {
          [self.firstSyncViewController.view removeFromSuperview];
          self.firstSyncViewController = nil;
        }];
      }
    });
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; 
}

@end
