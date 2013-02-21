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

#define kMVRatio 800
#define kMVDuration 0.2

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVRootViewController () <UIGestureRecognizerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;
@property (strong, readwrite) MVAlbumsViewController *albumsViewController;
@property (strong, readwrite) UIView *mainView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVRootViewController

@synthesize coreManager               = coreManager_,
            contextSource             = contextSource_,
            albumsViewController      = albumsViewController_,
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
    mainView_ = nil;
  }
  return self;
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
  
  self.albumsViewController.view.frame = self.mainView.bounds;
  [self.mainView addSubview:self.albumsViewController.view];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload
{
  [self.albumsViewController.view removeFromSuperview];
}

@end
