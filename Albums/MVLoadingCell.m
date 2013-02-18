//
//  MVLoadingCell.m
//  Albums
//
//  Created by Michaël Villar on 1/9/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import "MVLoadingCell.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVLoadingCell ()

@property (strong, readwrite) UIActivityIndicatorView *activityIndicatorView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVLoadingCell

@synthesize activityIndicatorView       = activityIndicatorView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)rowHeight
{
  return 50;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if(self)
  {
    activityIndicatorView_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                              UIActivityIndicatorViewStyleWhite];
    activityIndicatorView_.color = [UIColor blackColor];
    [activityIndicatorView_ startAnimating];
    [self addSubview:activityIndicatorView_];
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect
{
  [kMVCellBgColor set];
  [[UIBezierPath bezierPathWithRect:self.bounds] fill];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
  [super layoutSubviews];
  
  CGRect activityIndicatorViewFrame = self.activityIndicatorView.frame;
  activityIndicatorViewFrame.origin.x = round((self.frame.size.width -
                                               activityIndicatorViewFrame.size.width) / 2);
  activityIndicatorViewFrame.origin.y = round((self.frame.size.height -
                                               activityIndicatorViewFrame.size.height) / 2);
  self.activityIndicatorView.frame = activityIndicatorViewFrame;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
}

@end
