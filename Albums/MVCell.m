//
//  MVCell.m
//  Albums
//
//  Created by Michaël Villar on 1/9/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import "MVCell.h"
#import "MVView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCell ()

@property (strong, readwrite) MVView *topCorners;
@property (strong, readwrite) MVView *bottomCorners;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCell

@synthesize topCorners    = topCorners_,
            bottomCorners = bottomCorners_,
            tableView     = tableView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {
    __block MVCell *cell = self;
    
    tableView_ = nil;

    topCorners_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    topCorners_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    topCorners_.userInteractionEnabled = NO;
    topCorners_.backgroundColor = [UIColor clearColor];
    topCorners_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      float y = 0;
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, y + kMVCellRadius)];
      [path addCurveToPoint:CGPointMake(kMVCellRadius, y)
              controlPoint1:CGPointMake(0, y)
              controlPoint2:CGPointMake(kMVCellRadius, y)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVCellRadius,
                                       y)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, y + kMVCellRadius)
              controlPoint1:CGPointMake(view.frame.size.width, y)
              controlPoint2:CGPointMake(view.frame.size.width, y + kMVCellRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width,
                                       y)];
      [path addLineToPoint:CGPointMake(0, y)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
    
    bottomCorners_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    bottomCorners_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    bottomCorners_.userInteractionEnabled = NO;
    bottomCorners_.backgroundColor = [UIColor clearColor];
    bottomCorners_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      float y = cell.bounds.size.height - 1 - kMVCellRadius;
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, y)];
      [path addCurveToPoint:CGPointMake(kMVCellRadius, y + kMVCellRadius)
              controlPoint1:CGPointMake(0, y + kMVCellRadius)
              controlPoint2:CGPointMake(kMVCellRadius, y + kMVCellRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVCellRadius,
                                       y + kMVCellRadius)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, y)
              controlPoint1:CGPointMake(view.frame.size.width, y + kMVCellRadius)
              controlPoint2:CGPointMake(view.frame.size.width, y)];
      [path addLineToPoint:CGPointMake(view.frame.size.width,
                                       y + kMVCellRadius + 1)];
      [path addLineToPoint:CGPointMake(0, y + kMVCellRadius + 1)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
  [super layoutSubviews];
  
  NSIndexPath *indexPath = [self.tableView indexPathForCell:self];
  NSInteger numberOfRows = [self.tableView numberOfRowsInSection:indexPath.section];
  
  [self.bottomCorners removeFromSuperview];
  [self.topCorners removeFromSuperview];
  
  if(indexPath.row == numberOfRows - 1)
  {
    self.bottomCorners.frame = self.contentView.bounds;
    [self.contentView addSubview:self.bottomCorners];
  }
  if(indexPath.row == 0)
  {
    self.topCorners.frame = self.contentView.bounds;
    [self.contentView addSubview:self.topCorners];
  }
}

@end
