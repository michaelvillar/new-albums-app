//
//  MVSectionView.m
//  Albums
//
//  Created by Michaël on 9/30/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVSectionView.h"
#import "MVView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVSectionView ()

@property (strong, readwrite) MVView *roundedBottomCorners;
@property (strong, readwrite) MVView *roundedTopCorners;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVSectionView

@synthesize roundedBottomCorners      = roundedBottomCorners_,
            roundedTopCorners         = roundedTopCorners_,
            label                     = label_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    self.clipsToBounds = NO;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
   
    label_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect
{
  if(self.label)
  {
    UIFont *font = [UIFont boldSystemFontOfSize:18];
    CGSize labelSize = [self.label sizeWithFont:font];
    
    CGRect labelRect = CGRectMake((self.bounds.size.width - labelSize.width) / 2, 12,
                                  labelSize.width, kMVSectionViewRoundedRectHeight);
    labelRect = CGRectIntegral(labelRect);
    CGRect roundedRect = CGRectInset(labelRect, - 13, 0);
    
    [[UIColor colorWithRed:0.3373 green:0.3608 blue:0.4157 alpha:1.0000] set];
//    [[UIBezierPath bezierPathWithRoundedRect:roundedRect
//                                cornerRadius:kMVSectionViewRoundedRectHeight / 2] fill];
    
    [[UIColor whiteColor] set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(context, CGSizeMake(0.0, 1.0), 1.0,
                                [UIColor colorWithWhite:0 alpha:0.42].CGColor);
    [self.label drawAtPoint:CGPointMake(labelRect.origin.x, labelRect.origin.y + 1) withFont:font];
  }
}

@end
