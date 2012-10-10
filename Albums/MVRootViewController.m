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

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVRootViewController () <UIGestureRecognizerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;
@property (strong, readwrite) MVAlbumsViewController *releasedAlbumsViewController;
@property (strong, readwrite) MVAlbumsViewController *upcomingAlbumsViewController;
@property (strong, readwrite) UIView *mainView;

// Pan support
@property (readwrite) CGPoint locationBeforePan;

- (void)undoPan;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVRootViewController

@synthesize coreManager               = coreManager_,
            contextSource             = contextSource_,
            releasedAlbumsViewController  = releasedAlbumsViewController_,
            upcomingAlbumsViewController  = upcomingAlbumsViewController_,
            mainView                  = mainView_,
            locationBeforePan         = locationBeforePan_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
{
  self = [super init];
  if (self)
  {
    contextSource_ = contextSource;
    coreManager_ = coreManager;
    releasedAlbumsViewController_ = [[MVAlbumsViewController alloc]
                                     initWithContextSource:contextSource
                                     coreManager:coreManager
                                     type:kMVAlbumsViewControllerTypeReleased];
    upcomingAlbumsViewController_ = [[MVAlbumsViewController alloc]
                                     initWithContextSource:contextSource
                                     coreManager:coreManager
                                     type:kMVAlbumsViewControllerTypeUpcoming];
    mainView_ = nil;
    locationBeforePan_ = CGPointZero;
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

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(dragContentView:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 2.5 / -2000;
    self.mainView.layer.sublayerTransform = transform;
  }
  
  self.releasedAlbumsViewController.view.frame = CGRectMake(self.view.bounds.size.width / 2, 0,
                                                            self.view.bounds.size.width,
                                                            self.view.bounds.size.height);
  self.releasedAlbumsViewController.view.layer.anchorPoint = CGPointMake(1, 0.5);
  [self.mainView addSubview:self.releasedAlbumsViewController.view];

  self.upcomingAlbumsViewController.view.frame = CGRectMake(self.view.bounds.size.width / 2, 0,
                                                            self.view.bounds.size.width,
                                                            self.view.bounds.size.height);
  self.upcomingAlbumsViewController.view.layer.anchorPoint = CGPointMake(0, 0.5);
  [self.mainView addSubview:self.upcomingAlbumsViewController.view];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload
{
  [self.releasedAlbumsViewController.view removeFromSuperview];
  [self.upcomingAlbumsViewController.view removeFromSuperview];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Pan Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if (gestureRecognizer.view == self.view &&
      [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
  {
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint translate = [pan translationInView:self.view];
    BOOL possible = translate.x != 0 && ((fabsf(translate.y) / fabsf(translate.x)) < 1.0f);
    return possible;
  }
  return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dragContentView:(UIPanGestureRecognizer *)panGesture
{
  if(panGesture.state == UIGestureRecognizerStateBegan)
  {
    self.locationBeforePan = self.mainView.frame.origin;
  }
  
  CGPoint translate = [panGesture translationInView:self.view];
  CGRect frame = self.mainView.frame;
  frame.origin.x = self.locationBeforePan.x + translate.x;
  self.mainView.frame = frame;
  
  CATransform3D transform = CATransform3DMakeRotation(translate.x / kMVRatio, 0, 1, 0);
  self.releasedAlbumsViewController.view.layer.transform = transform;
  self.releasedAlbumsViewController.gradientOpacity = 1.4 * fabs(translate.x / self.view.frame.size.width);
  
  transform = CATransform3DMakeRotation((self.view.frame.size.width + translate.x) / kMVRatio, 0, 1, 0);
  self.upcomingAlbumsViewController.view.layer.transform = transform;
  self.upcomingAlbumsViewController.gradientOpacity = - 1.4 * fabs((self.view.frame.size.width - fabs(translate.x)) / self.view.frame.size.width);
  
  if (panGesture.state == UIGestureRecognizerStateEnded)
  {
    [self undoPan];
  }
  else if (panGesture.state == UIGestureRecognizerStateCancelled)
  {
    [self undoPan];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)undoPan
{
  [UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    CGRect frame = self.mainView.frame;
    frame.origin = self.locationBeforePan;
    self.mainView.frame = frame;
    self.releasedAlbumsViewController.view.layer.transform = CATransform3DIdentity;
    self.releasedAlbumsViewController.gradientOpacity = 0.0;
    
    CATransform3D transform = CATransform3DMakeRotation(self.view.frame.size.width / kMVRatio, 0, 1, 0);
    self.upcomingAlbumsViewController.view.layer.transform = transform;
    self.upcomingAlbumsViewController.gradientOpacity = 1.0;
  } completion:^(BOOL finished) {
  }];
}

@end
