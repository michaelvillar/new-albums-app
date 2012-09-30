//
//  MVLoadingView.m
//  Albums
//
//  Created by Michaël on 9/30/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVLoadingView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVLoadingView

@synthesize label   = label_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(self)
  {
    self.backgroundColor = [UIColor clearColor];
    
    label_ = NSLocalizedString(@"Loading", @"Loading");
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect
{
  [[UIColor colorWithWhite:0 alpha:0.8] set];
  [[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:12] fill];
  
  [[UIColor whiteColor] set];
  float y = roundf((self.bounds.size.height - 26) / 2);
  [self.label drawInRect:CGRectMake(20, y, self.bounds.size.width - 40, 26)
                withFont:[UIFont boldSystemFontOfSize:18]
           lineBreakMode:NSLineBreakByTruncatingTail
               alignment:NSTextAlignmentCenter];
}

@end
