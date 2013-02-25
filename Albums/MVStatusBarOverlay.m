//
//  MVStatusBarView.m
//  Albums
//
//  Created by Michaël Villar on 2/25/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import "MVStatusBarOverlay.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVStatusBarOverlay ()

@property (strong, readwrite) UIView *view;
@property (strong, readwrite) UILabel *label;
@property (readwrite, getter = isOverlayHidden) BOOL overlayHidden;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVStatusBarOverlay

// -- Public
@synthesize text              = text_;

// -- Private
@synthesize view              = view_,
            label             = label_,
            overlayHidden     = overlayHidden_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  CGRect frame = [UIApplication sharedApplication].statusBarFrame;
  frame.size.height = 20;
  self = [self initWithFrame:frame];
  if (self)
  {
    self.windowLevel = UIWindowLevelStatusBar+1.f;
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidBecomeActive:)
               name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(applicationWillResignActive:)
               name:UIApplicationWillResignActiveNotification object:nil];

    view_ = [[UIView alloc] initWithFrame:self.bounds];
    view_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view_.backgroundColor = [UIColor blackColor];
    view_.hidden = YES;
    view_.alpha = 0.0;
    
    CGRect labelFrame = CGRectInset(self.bounds, 10, 0);
    label_ = [[UILabel alloc] initWithFrame:labelFrame];
    label_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                              UIViewAutoresizingFlexibleRightMargin;
    label_.font = [UIFont boldSystemFontOfSize:14];
    label_.textAlignment = UITextAlignmentCenter;
    label_.textColor = [UIColor colorWithRed:0.749f green:0.749f blue:0.749f alpha:1.0f];
    label_.backgroundColor = [UIColor clearColor];
    
    [self addSubview:view_];
    [view_ addSubview:label_];
    
    overlayHidden_ = YES;
    text_ = @"";
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOverlayHidden:(BOOL)hidden
                animated:(BOOL)animated
{
  if(self.overlayHidden == hidden)
    return;
  
  self.overlayHidden = hidden;
  if(!hidden)
  {
    self.view.hidden = NO;
    [UIView animateWithDuration:0.15 animations:^{
      self.view.alpha = 1.0;
    }];
  }
  else
  {
    [UIView animateWithDuration:0.15 animations:^{
      self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
      self.view.hidden = YES;
    }];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setText:(NSString *)text
{
  if([text_ isEqualToString:text])
    return;
  text_ = text;
  self.label.text = text;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Notifications

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillResignActive:(NSNotification *)notifaction
{
  // We hide temporary when the application resigns active s.t the overlay
  // doesn't overlay the Notification Center. Let's hope this helps AppStore
  // Approval ...
  self.hidden = YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(NSNotification *)notifaction
{
  self.hidden = NO;
}


@end
