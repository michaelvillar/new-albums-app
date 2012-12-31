//
//  MVAlbumCell.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVAlbumCell.h"
#import "MVAlbum.h"
#import "MVArtist.h"
#import "MVAsset.h"
#import "MVAssetsManager.h"
#import "MVView.h"
#import "MVSectionView.h"

#define kMVAlbumArtSize 60

#define kMVAlbumBgColor [UIColor colorWithRed:0.9129 green:0.9129 blue:0.9129 alpha:1.0000]

static NSCache *artworkImagesCache = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumCell ()

@property (strong, readwrite) MVAsset *artworkAsset;
@property (strong, readwrite) UIImage *artworkImage;
@property (strong, readwrite) MVView *albumView;
@property (strong, readwrite) MVView *topCorners;
@property (strong, readwrite) MVView *bottomCorners;

- (void)generateArtworkImage;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumCell

@synthesize tableView     = tableView_,
            album         = album_,
            artworkAsset  = artworkAsset_,
            artworkImage  = artworkImage_,
            albumView     = albumView_,
            topCorners    = topCorners_,
            bottomCorners = bottomCorners_;

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)rowHeight
{
  return kMVAlbumArtSize;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)initialize
{
  if(!artworkImagesCache)
    artworkImagesCache = [[NSCache alloc] init];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if(self)
  {
    tableView_ = nil;
    album_ = nil;
    artworkAsset_ = nil;
    artworkImage_ = nil;
    
    __block MVAlbumCell *cell = self;
    
    self.contentView.backgroundColor = [UIColor colorWithRed:0.4365 green:0.4365
                                                        blue:0.4365 alpha:1.0000];

    self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    albumView_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    albumView_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight;
    albumView_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      if(!cell.album)
        return;

      float marginLeft = kMVAlbumArtSize + 3;
      float marginTop = 0;
      float availableWidth = view.bounds.size.width - marginLeft - 6 * 2 - 12;
      CGRect artworkRect = CGRectMake(0, 0, kMVAlbumArtSize, kMVAlbumArtSize);

      if(!cell.artworkAsset)
      {
        NSURL *url = [NSURL URLWithString:cell.album.artworkUrl];
        cell.artworkAsset = [[MVAssetsManager sharedAssetsManager] assetForRemoteURL:url];
        [cell.artworkAsset addObserver:cell forKeyPath:@"existing" options:0 context:NULL];
        if(cell.artworkAsset.isExisting)
        {
          cell.artworkImage = [artworkImagesCache objectForKey:cell.artworkAsset.localURL.path];
          if(!cell.artworkImage)
            [cell generateArtworkImage];
        }
      }

      [kMVAlbumBgColor set];
      [[UIBezierPath bezierPathWithRect:view.bounds] fill];
      
      if(cell.artworkImage)
      {
        [cell.artworkImage drawInRect:artworkRect];
      }

      if(self.isHighlighted)
      {
        [[UIColor colorWithWhite:0 alpha:0.5] set];
        [[UIBezierPath bezierPathWithRect:view.bounds] fill];
      }
      
      if([cell.album.releaseDate compare:[NSDate date]] == NSOrderedDescending)
      {
        NSString *releaseDate = cell.album.monthDayReleaseDate;
        UIFont *font = [UIFont boldSystemFontOfSize:14];
        CGSize labelSize = [releaseDate sizeWithFont:font];
        
        CGFloat labelWidth = ceilf(labelSize.width + 5 * 2);
        CGRect labelRect = CGRectMake(cell.frame.size.width - labelWidth - 10, 20, labelWidth, 20);
        availableWidth -= labelRect.size.width + 2;
        
        [[UIColor colorWithRed:0.9765 green:0.6471 blue:0.1882 alpha:1.0000] set];
        [[UIBezierPath bezierPathWithRoundedRect:labelRect
                                    cornerRadius:10] fill];
        
        [[UIColor whiteColor] set];
        [releaseDate drawAtPoint:CGPointMake(labelRect.origin.x + 5, labelRect.origin.y + 1)
                        forWidth:labelWidth
                        withFont:font
                   lineBreakMode:NSLineBreakByCharWrapping];
      }
      
      if(self.isHighlighted)
      {
        [[UIColor whiteColor] set];
      }
      else
      {
        [[UIColor colorWithRed:0.1971 green:0.1971 blue:0.1971 alpha:1.0000] set];
      }
      [cell.album.artist.name drawAtPoint:CGPointMake(marginLeft + 8, marginTop + 11)
                                 forWidth:availableWidth
                                 withFont:[UIFont boldSystemFontOfSize:18]
                            lineBreakMode:NSLineBreakByTruncatingMiddle];
      
      if(self.isHighlighted)
      {
        [[UIColor colorWithRed:0.8624 green:0.8624 blue:0.8624 alpha:1.0000] set];
      }
      else
      {
        [[UIColor colorWithRed:0.5581 green:0.5581 blue:0.5581 alpha:1.0000] set];
      }
      [cell.album.shortName drawAtPoint:CGPointMake(marginLeft + 8, marginTop + 33)
                               forWidth:availableWidth
                               withFont:[UIFont systemFontOfSize:13]
                          lineBreakMode:NSLineBreakByTruncatingMiddle];
    };
    albumView_.layer.shadowColor = [UIColor blackColor].CGColor;
    albumView_.layer.shadowRadius = 3;
    albumView_.layer.shadowOffset = CGSizeMake(0, 0);
    albumView_.layer.shadowOpacity = 0.0;
    [self.contentView addSubview:albumView_];
    
    topCorners_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    topCorners_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight;
    topCorners_.userInteractionEnabled = NO;
    topCorners_.backgroundColor = [UIColor clearColor];
    topCorners_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      float y = 0;
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, y + kMVSectionViewRadius)];
      [path addCurveToPoint:CGPointMake(kMVSectionViewRadius, y)
              controlPoint1:CGPointMake(0, y)
              controlPoint2:CGPointMake(kMVSectionViewRadius, y)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVSectionViewRadius,
                                       y)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, y + kMVSectionViewRadius)
              controlPoint1:CGPointMake(view.frame.size.width, y)
              controlPoint2:CGPointMake(view.frame.size.width, y + kMVSectionViewRadius)];
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
      float y = cell.bounds.size.height - 1 - kMVSectionViewRadius;
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, y)];
      [path addCurveToPoint:CGPointMake(kMVSectionViewRadius, y + kMVSectionViewRadius)
              controlPoint1:CGPointMake(0, y + kMVSectionViewRadius)
              controlPoint2:CGPointMake(kMVSectionViewRadius, y + kMVSectionViewRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVSectionViewRadius,
                                       y + kMVSectionViewRadius)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, y)
              controlPoint1:CGPointMake(view.frame.size.width, y + kMVSectionViewRadius)
              controlPoint2:CGPointMake(view.frame.size.width, y)];
      [path addLineToPoint:CGPointMake(view.frame.size.width,
                                       y + kMVSectionViewRadius + 1)];
      [path addLineToPoint:CGPointMake(0, y + kMVSectionViewRadius + 1)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(panGestureRecognizer:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    [self.contentView addGestureRecognizer:panGesture];
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  if(self.artworkAsset)
    [self.artworkAsset removeObserver:self forKeyPath:@"existing"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setAlbum:(MVAlbum *)album
{
  if(album == album_)
    return;
  if(self.artworkAsset)
    [self.artworkAsset removeObserver:self forKeyPath:@"existing"];
  album_ = album;
  self.artworkAsset = nil;
  self.artworkImage = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if([keyPath isEqualToString:@"existing"] &&
     object == self.artworkAsset &&
     self.artworkAsset.isExisting)
  {
    [self generateArtworkImage];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect
{
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setNeedsDisplay
{
  [self.albumView setNeedsDisplay];
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
    [self.contentView addSubview:self.bottomCorners];
  }
  if(indexPath.row == 0)
  {
    [self.contentView addSubview:self.topCorners];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Pan Gesture

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if (gestureRecognizer.view == self.contentView &&
      [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
  {
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint translate = [pan translationInView:self.contentView];
    BOOL possible = translate.x != 0 && ((fabsf(translate.y) / fabsf(translate.x)) < 1.0f);
    return possible;
  }
  return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)panGestureRecognizer:(UIPanGestureRecognizer *)panGesture
{
  CGPoint translate = [panGesture translationInView:self.contentView];
  CGRect frame = self.albumView.frame;
  
  if(panGesture.state == UIGestureRecognizerStateEnded)
  {
    frame.origin.x = 0;
    
    [UIView animateWithDuration:0.15 animations:^{
      self.albumView.frame = frame;
    }];
    
    if(self.albumView.layer.shadowOpacity != 0.0)
    {
      CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
      anim.fromValue = [NSNumber numberWithFloat:self.albumView.layer.shadowOpacity];
      anim.toValue = [NSNumber numberWithFloat:0.0];
      anim.duration = 0.15;
      [self.albumView.layer addAnimation:anim forKey:@"shadowOpacity"];
      self.albumView.layer.shadowOpacity = 0.0;
    }
    
    self.layer.zPosition = 0;
  }
  else
  {
    frame.origin.x = translate.x;
    self.albumView.frame = frame;
    
    if(self.albumView.layer.shadowOpacity != 0.5)
    {
      CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
      anim.fromValue = [NSNumber numberWithFloat:self.albumView.layer.shadowOpacity];
      anim.toValue = [NSNumber numberWithFloat:0.5];
      anim.duration = 0.15;
      [self.albumView.layer addAnimation:anim forKey:@"shadowOpacity"];
      self.albumView.layer.shadowOpacity = 0.5;
    }
    
    self.layer.zPosition = 1000;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)generateArtworkImage
{
  __strong __block MVAlbumCell *cell = self;
  __strong __block MVAsset *asset = self.artworkAsset;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    UIImage *image = [artworkImagesCache objectForKey:asset.localURL.path];
    if(!image)
    {
      image = [UIImage imageWithContentsOfFile:asset.localURL.path];
      
      CGSize newSize = CGSizeMake(kMVAlbumArtSize * 2, kMVAlbumArtSize * 2);
      UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
      [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
      UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      
      image = newImage;
      
      if(image)
      {
        [artworkImagesCache setObject:image forKey:asset.localURL.path];
      }
    }
    if(asset == cell.artworkAsset)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *indexPath = [cell.tableView indexPathForCell:cell];
        if(indexPath)
        {
          [cell.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                withRowAnimation:UITableViewRowAnimationNone];
        }
      });
    }
  });
}

@end
