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
#import "MVSettingsViewController.h"
#import "MVViewController.h"

#define kMVRatio 800
#define kMVDuration 0.2

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVRootViewController () <UIGestureRecognizerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;
@property (strong, readwrite) MVAlbumsViewController *releasedAlbumsViewController;
@property (strong, readwrite) MVAlbumsViewController *upcomingAlbumsViewController;
@property (strong, readwrite) NSMutableArray *viewControllers;
@property (strong, readwrite) MVViewController *currentController;
@property (strong, readwrite) UIView *mainView;

@property (strong, readonly, nonatomic) MVViewController *previousController;
@property (strong, readonly, nonatomic) MVViewController *nextController;

// Pan support
@property (readwrite) CGPoint locationBeforePan;
@property (readwrite) CGFloat lastDeltaX;

- (void)undoPan;
- (void)layoutViewControllers;
- (void)updateCurrentControllerAnchorPointWithX:(CGFloat)anchorPointX;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVRootViewController

@synthesize coreManager               = coreManager_,
            contextSource             = contextSource_,
            releasedAlbumsViewController  = releasedAlbumsViewController_,
            upcomingAlbumsViewController  = upcomingAlbumsViewController_,
            viewControllers           = viewControllers_,
            currentController         = currentController_,
            mainView                  = mainView_,
            locationBeforePan         = locationBeforePan_,
            lastDeltaX                = lastDeltaX_;

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
    viewControllers_ = [NSArray arrayWithObjects:
                        releasedAlbumsViewController_,
                        upcomingAlbumsViewController_,
                        [[MVSettingsViewController alloc] init],
                        nil];
    currentController_ = releasedAlbumsViewController_;
    mainView_ = nil;
    locationBeforePan_ = CGPointZero;
    lastDeltaX_ = 0;
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

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dragContentView:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 2.5 / -2000;
    self.mainView.layer.sublayerTransform = transform;
  }
  
  [self layoutViewControllers];
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
#pragma mark Private Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (MVViewController*)previousController
{
  NSUInteger index = [self.viewControllers indexOfObject:self.currentController];
  if(index > 0)
    return [self.viewControllers objectAtIndex:index-1];
  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (MVViewController*)nextController
{
  NSUInteger index = [self.viewControllers indexOfObject:self.currentController];
  if(index < self.viewControllers.count - 1)
    return [self.viewControllers objectAtIndex:index+1];
  return nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Layouting

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutViewControllers
{
  UIViewController *controller;
  for(controller in self.viewControllers)
    [controller.view removeFromSuperview];
  
  UIViewController *previousController = self.previousController;
  if(previousController)
  {
    previousController.view.layer.anchorPoint = CGPointMake(1, 0.5);
    previousController.view.frame = CGRectMake(- self.view.bounds.size.width, 0,
                                               self.view.bounds.size.width,
                                               self.view.bounds.size.height);
    [self.mainView addSubview:previousController.view];
  }

  self.currentController.view.layer.anchorPoint = CGPointMake(0.5, 0.5);
  self.currentController.view.frame = self.view.bounds;
  [self.mainView addSubview:self.currentController.view];
  
  UIViewController *nextController = self.nextController;
  if(nextController)
  {
    nextController.view.layer.anchorPoint = CGPointMake(0, 0.5);
    nextController.view.frame = CGRectMake(self.view.bounds.size.width, 0,
                                           self.view.bounds.size.width,
                                           self.view.bounds.size.height);
    [self.mainView addSubview:nextController.view];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateCurrentControllerAnchorPointWithX:(CGFloat)anchorPointX
{
  if(self.currentController.view.layer.anchorPoint.x == anchorPointX)
    return;
  self.currentController.view.layer.anchorPoint = CGPointMake(anchorPointX, 0.5);
  self.currentController.view.frame = self.view.bounds;

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
  float newX = self.locationBeforePan.x;
  if((translate.x > 0 && !self.previousController) ||
     (translate.x < 0 && !self.nextController))
    newX += translate.x * 0.4;
  else
    newX += translate.x;
  if(panGesture.state != UIGestureRecognizerStateEnded)
    self.lastDeltaX = - self.mainView.frame.origin.x + newX;
  frame.origin.x = newX;
  self.mainView.frame = frame;
  
  BOOL willGoNext = (frame.origin.x > self.locationBeforePan.x);
  [self updateCurrentControllerAnchorPointWithX:(willGoNext ? 0 : 1)];
  
  CATransform3D transform = CATransform3DMakeRotation(translate.x / kMVRatio, 0, 1, 0);
  self.currentController.view.layer.transform = transform;
  self.currentController.gradientOpacity = (willGoNext ? -1 : 1) *
                                           (1.4 * fabs(translate.x / self.view.frame.size.width));
  
  MVViewController *nextController = self.nextController;
  if(nextController)
  {
    transform = CATransform3DMakeRotation((self.view.frame.size.width + translate.x) / kMVRatio,
                                          0, 1, 0);
    nextController.view.layer.transform = transform;
    nextController.gradientOpacity = - 1.4 * fabs((self.view.frame.size.width -
                                                   fabs(translate.x)) /
                                                  self.view.frame.size.width);
  }
  
  MVViewController *previousController = self.previousController;
  if(previousController)
  {
    transform = CATransform3DMakeRotation((- self.view.frame.size.width + translate.x) / kMVRatio,
                                          0, 1, 0);
    previousController.view.layer.transform = transform;
    previousController.gradientOpacity = 1.4 * fabs((self.view.frame.size.width -
                                                       fabs(translate.x)) /
                                                      self.view.frame.size.width);
  }
  
  if(panGesture.state == UIGestureRecognizerStateEnded)
  {
    float velocity = [panGesture velocityInView:self.view].x;
    float xDiff = self.lastDeltaX;
    xDiff = (fabsf(xDiff) < 2 ? 0 : xDiff);
    BOOL switchToNext = NO;
    BOOL switchToPrevious = NO;
    if(xDiff > 0 && velocity > 10 && self.previousController)
    {
      self.currentController = self.previousController;
      switchToPrevious = YES;
    }
    else if(xDiff < 0 && velocity < -10 &&self.nextController)
    {
      self.currentController = self.nextController;
      switchToNext = YES;
    }
    else if(xDiff == 0 &&
            self.mainView.frame.origin.x >= self.mainView.frame.size.width / 2 &&
            self.previousController)
    {
      self.currentController = self.previousController;
      switchToPrevious = YES;
    }
    else if(xDiff == 0 &&
            self.mainView.frame.origin.x <= - self.mainView.frame.size.width / 2 &&
            self.nextController)
    {
      self.currentController = self.nextController;
      switchToNext = YES;
    }
    else
      [self undoPan];
    
    if(switchToNext || switchToPrevious)
    {
      [UIView animateWithDuration:kMVDuration
                            delay:0.0f
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^
      {
        CGRect frame = self.mainView.frame;
        frame.origin = CGPointMake(switchToNext ?
                                   -self.view.bounds.size.width :
                                   self.view.bounds.size.width, 0);
        self.mainView.frame = frame;
        self.currentController.view.layer.transform = CATransform3DIdentity;
        self.currentController.gradientOpacity = 0.0;
      } completion:^(BOOL finished) {
        [self layoutViewControllers];
        self.mainView.frame = self.view.bounds;
      }];
    }
  }
  else if(panGesture.state == UIGestureRecognizerStateCancelled)
  {
    [self undoPan];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)undoPan
{
  [UIView animateWithDuration:kMVDuration
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
  {
    CGRect frame = self.mainView.frame;
    frame.origin = CGPointZero;
    self.mainView.frame = frame;
    self.currentController.view.layer.transform = CATransform3DIdentity;
    self.currentController.gradientOpacity = 0.0;

    MVViewController *nextController = self.nextController;
    if(nextController)
    {
      CATransform3D transform = CATransform3DMakeRotation(self.view.frame.size.width / kMVRatio,
                                                          0, 1, 0);
      nextController.view.layer.transform = transform;
      nextController.gradientOpacity = 1.0;
    }
    
    MVViewController *previousController = self.previousController;
    if(previousController)
    {
      CATransform3D transform = CATransform3DMakeRotation(- self.view.frame.size.width / kMVRatio,
                                                          0, 1, 0);
      previousController.view.layer.transform = transform;
      previousController.gradientOpacity = 1.0;
    }
  } completion:^(BOOL finished) {
  }];
}

@end
