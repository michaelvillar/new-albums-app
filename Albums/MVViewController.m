//
//  MVViewController.m
//  Albums
//
//  Created by Michaël on 10/13/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVViewController.h"
#import "MVView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVViewController ()

@property (strong, readwrite) MVView *gradientShadowView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVViewController

@synthesize gradientShadowView        = gradientShadowView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    gradientShadowView_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView
{
  if(!self.gradientShadowView)
  {
    self.gradientShadowView = [[MVView alloc] initWithFrame:self.view.bounds];
    self.gradientShadowView.userInteractionEnabled = NO;
    self.gradientShadowView.backgroundColor = [UIColor clearColor];
    self.gradientShadowView.opaque = NO;
    self.gradientShadowView.alpha = 0.0;
    self.gradientShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    self.gradientShadowView.drawBlock = ^(UIView *view, CGContextRef ref)
    {
      CGContextRef context = UIGraphicsGetCurrentContext();
      
      CGContextSaveGState(context);
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      CGGradientRef gradient = CGGradientCreateWithColorComponents
      (colorSpace,
       (const CGFloat[8]){0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.4},
       (const CGFloat[2]){0.0f,1.0f},
       2);
      
      CGContextDrawLinearGradient(context,
                                  gradient,
                                  CGPointMake(CGRectGetMinX(view.bounds), CGRectGetMidY(view.bounds)),
                                  CGPointMake(CGRectGetMaxX(view.bounds), CGRectGetMidY(view.bounds)),
                                  0);
      
      CGColorSpaceRelease(colorSpace);
      CGContextRestoreGState(context);
    };
  }
  [self.view addSubview:self.gradientShadowView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setGradientOpacity:(float)gradientOpacity
{
  float alpha = MIN(1,MAX(0,fabs(gradientOpacity)));
  if(gradientOpacity != 0 && gradientOpacity != 1)
  {
    CATransform3D transform;
    if(gradientOpacity < 0)
    {
      transform = CATransform3DMakeScale(-1, 1, 1);
    }
    else
    {
      transform = CATransform3DIdentity;
    }
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    self.gradientShadowView.layer.transform = transform;
    [UIView setAnimationsEnabled:animationsEnabled];
  }
  self.gradientShadowView.alpha = alpha;
}


@end
