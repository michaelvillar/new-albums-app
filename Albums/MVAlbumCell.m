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
#import "MVRoundedLabelView.h"

#define kMVAlbumArtSize 60

#define kMVAlbumContentViewBgColor0 [UIColor colorWithRed:0.2703 green:0.2703 blue:0.2703 alpha:1]
#define kMVAlbumContentViewBgColor1 [UIColor colorWithRed:0.4365 green:0.4365 blue:0.4365 alpha:1]
#define kMVAlbumContentViewBgColor2 [UIColor colorWithRed:0.2703 green:0.2703 blue:0.2703 alpha:1]

#define kMVAlbumControlStartMargin 2
#define kMVAlbumControlEndMarginFromY -6

static NSCache *artworkImagesCache = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumCell ()

@property (strong, readwrite) MVAsset *artworkAsset;
@property (strong, readwrite) UIImage *artworkImage;
@property (strong, readwrite) MVView *albumView;
@property (strong, readwrite) MVView *artworkView;
@property (strong, readwrite) MVRoundedLabelView *hideAlbumLabelView;
@property (strong, readwrite) MVRoundedLabelView *hideArtistLabelView;

- (void)generateArtworkImageAndDisplay:(BOOL)animated;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumCell

@synthesize album         = album_,
            artworkAsset  = artworkAsset_,
            artworkImage  = artworkImage_,
            albumView     = albumView_,
            artworkView   = artworkView_,
            hideAlbumLabelView = hideAlbumLabelView_,
            hideArtistLabelView = hideArtistLabelView_,
            delegate      = delegate_;

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
    album_ = nil;
    artworkAsset_ = nil;
    artworkImage_ = nil;
    delegate_ = nil;
    
    __block MVAlbumCell *cell = self;
    
    MVView *contentView = [[MVView alloc] initWithFrame:self.contentView.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight;
    contentView.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      CGContextRef context = UIGraphicsGetCurrentContext();
      
      CGContextSaveGState(context);
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      
      CGFloat locations[4];
      NSMutableArray *colors = [NSMutableArray arrayWithCapacity:4];
      [colors addObject:(id)kMVAlbumContentViewBgColor0.CGColor];
      locations[0] = 0.0;
      [colors addObject:(id)kMVAlbumContentViewBgColor1.CGColor];
      locations[1] = 0.05;
      [colors addObject:(id)kMVAlbumContentViewBgColor1.CGColor];
      locations[2] = 0.95;
      [colors addObject:(id)kMVAlbumContentViewBgColor2.CGColor];
      locations[3] = 1;
      CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
      
      CGContextDrawLinearGradient(context,
                                  gradient,
                                  CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)),
                                  CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)),
                                  0);
      
      CGColorSpaceRelease(colorSpace);
      CGContextRestoreGState(context);
    };
    [self.contentView addSubview:contentView];
    
    hideAlbumLabelView_ = [[MVRoundedLabelView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    hideAlbumLabelView_.text = NSLocalizedString(@"Hide Album", @"Hide Album Label");
    [hideAlbumLabelView_ sizeToFit];
    [self.contentView addSubview:hideAlbumLabelView_];
    
    hideArtistLabelView_ = [[MVRoundedLabelView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    hideArtistLabelView_.text = NSLocalizedString(@"Hide Artist", @"Hide Artist Label");
    [hideArtistLabelView_ sizeToFit];
    [self.contentView addSubview:hideArtistLabelView_];

    self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    albumView_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    albumView_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight;
    albumView_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      if(!cell.album)
        return;

      float marginLeft = kMVAlbumArtSize + 11;
      float marginTop = 0;
      float marginRight = 10;

      [kMVCellBgColor set];
      [[UIBezierPath bezierPathWithRect:view.bounds] fill];

      if(cell.isHighlighted)
      {
        [[UIColor colorWithWhite:0 alpha:0.5] set];
        [[UIBezierPath bezierPathWithRect:view.bounds] fill];
      }
      
      if([cell.album.releaseDate compare:[NSDate date]] == NSOrderedDescending)
      {
        NSString *releaseDate = cell.album.monthDayReleaseDate;
        UIFont *font = [UIFont boldSystemFontOfSize:13];
        CGSize labelSize = [releaseDate sizeWithFont:font];
        
        CGFloat labelWidth = ceilf(labelSize.width + 5 * 2);
        CGRect labelRect = CGRectMake(cell.frame.size.width - marginRight - labelWidth, 20.5,
                                      labelWidth, 18);
        marginRight += labelRect.size.width + 3;
      
        if(cell.isHighlighted)
          [[UIColor colorWithWhite:0 alpha:0.6] set];
        else
          [[UIColor colorWithRed:0.9765 green:0.6471 blue:0.1882 alpha:1.0000] set];
        [[UIBezierPath bezierPathWithRoundedRect:labelRect
                                    cornerRadius:9] fill];
        
        [[UIColor whiteColor] set];
        [releaseDate drawAtPoint:CGPointMake(labelRect.origin.x + 5, labelRect.origin.y + 1)
                        forWidth:labelWidth
                        withFont:font
                   lineBreakMode:NSLineBreakByCharWrapping];
      }
      
      if(cell.album.albumType)
      {
        NSString *albumType = cell.album.albumType;
        UIFont *font = [UIFont systemFontOfSize:13];
        CGSize labelSize = [albumType sizeWithFont:font];
        
        marginRight += 3;
        CGPoint labelPoint = CGPointMake(cell.frame.size.width - marginRight - labelSize.width, 21.5);
        marginRight += labelSize.width + 3;
        
        if(cell.isHighlighted)
        {
          [[UIColor colorWithRed:0.8624 green:0.8624 blue:0.8624 alpha:1.0000] set];
        }
        else
        {
          [[UIColor colorWithRed:0.5581 green:0.5581 blue:0.5581 alpha:1.0000] set];
        }
        [albumType drawAtPoint:labelPoint withFont:font];
      }
      
      float availableWidth = view.bounds.size.width - marginLeft - marginRight;

      if(cell.isHighlighted)
      {
        [[UIColor whiteColor] set];
      }
      else
      {
        [[UIColor colorWithRed:0.1971 green:0.1971 blue:0.1971 alpha:1.0000] set];
      }
      [cell.album.artist.name drawAtPoint:CGPointMake(marginLeft, marginTop + 10.5)
                                 forWidth:availableWidth
                                 withFont:[UIFont boldSystemFontOfSize:18]
                            lineBreakMode:NSLineBreakByTruncatingMiddle];
      
      if(cell.isHighlighted)
      {
        [[UIColor colorWithRed:0.8624 green:0.8624 blue:0.8624 alpha:1.0000] set];
      }
      else
      {
        [[UIColor colorWithRed:0.5581 green:0.5581 blue:0.5581 alpha:1.0000] set];
      }
      [cell.album.shortName drawAtPoint:CGPointMake(marginLeft, marginTop + 32.5)
                               forWidth:availableWidth
                               withFont:[UIFont systemFontOfSize:13]
                          lineBreakMode:NSLineBreakByTruncatingMiddle];
    };
    albumView_.layer.shadowColor = [UIColor blackColor].CGColor;
    albumView_.layer.shadowRadius = 3;
    albumView_.layer.shadowOffset = CGSizeMake(0, 0);
    albumView_.layer.shadowOpacity = 0.0;
    [self.contentView addSubview:albumView_];
    
    artworkView_ = [[MVView alloc] initWithFrame:CGRectMake(0, 0,
                                                            kMVAlbumArtSize,
                                                            kMVAlbumArtSize)];
    artworkView_.backgroundColor = kMVCellBgColor;
    artworkView_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      if(!cell.album)
        return;
      
      CGRect artworkRect = CGRectMake(0, 0, kMVAlbumArtSize, kMVAlbumArtSize);
      
      if(!cell.artworkAsset)
      {
        NSURL *url = [NSURL URLWithString:cell.album.artworkUrl];
        cell.artworkAsset = [[MVAssetsManager sharedAssetsManager] assetForRemoteURL:url];
        [cell.artworkAsset addObserver:cell forKeyPath:@"existing" options:0 context:NULL];
      }
      if(!cell.artworkImage)
      {
        cell.artworkImage = [artworkImagesCache objectForKey:cell.artworkAsset.localURL.path];
        if(!cell.artworkImage && cell.artworkAsset.isExisting)
        {
          [cell generateArtworkImageAndDisplay:NO];
        }
      }
        
      if(cell.artworkImage)
      {
        [cell.artworkImage drawAtPoint:artworkRect.origin];
      }
      
      if(cell.isHighlighted)
      {
        [[UIColor colorWithWhite:0 alpha:0.5] set];
        [[UIBezierPath bezierPathWithRect:view.bounds] fill];
      }
    };
    [albumView_ addSubview:artworkView_];
        
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
  
  CGRect frame = self.albumView.frame;
  frame.origin.x = 0;
  self.albumView.frame = frame;
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
    [self generateArtworkImageAndDisplay:YES];
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
  [self.artworkView setNeedsDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
  [super layoutSubviews];
  
  CGRect hideAlbumLabelViewFrame = self.hideAlbumLabelView.frame;
  hideAlbumLabelViewFrame.origin.y = roundf((self.frame.size.height -
                                             hideAlbumLabelViewFrame.size.height) / 2);
  self.hideAlbumLabelView.frame = hideAlbumLabelViewFrame;
  
  CGRect hideArtistLabelViewFrame = self.hideArtistLabelView.frame;
  hideArtistLabelViewFrame.origin.y = roundf((self.frame.size.height -
                                             hideArtistLabelViewFrame.size.height) / 2);
  self.hideArtistLabelView.frame = hideArtistLabelViewFrame;
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
    
    if(self.albumView.layer.shadowOpacity != 0.0)
    {
      CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
      anim.fromValue = [NSNumber numberWithFloat:self.albumView.layer.shadowOpacity];
      anim.toValue = [NSNumber numberWithFloat:0.0];
      anim.duration = 0.15;
      [self.albumView.layer addAnimation:anim forKey:@"shadowOpacity"];
      self.albumView.layer.shadowOpacity = 0.0;
    }
    
    if(self.hideAlbumLabelView.isEnabled)
    {
      if([self.delegate respondsToSelector:@selector(albumCellDidTriggerHideAlbum:)])
        [self.delegate albumCellDidTriggerHideAlbum:self];
      frame.origin.x = frame.size.width + 10;
    }
    if(self.hideArtistLabelView.isEnabled)
    {
      if([self.delegate respondsToSelector:@selector(albumCellDidTriggerHideArtist:)])
        [self.delegate albumCellDidTriggerHideArtist:self];
    }
    
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction
                                             functionWithControlPoints:0.61 :1.5 :0.78 :1];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    animation.fromValue = [NSNumber numberWithFloat:self.albumView.frame.origin.x +
                                                    frame.size.width / 2];
    animation.toValue = [NSNumber numberWithFloat:frame.origin.x + frame.size.width / 2];
    animation.timingFunction = timingFunction;
    animation.duration = 0.3;
    [self.albumView.layer addAnimation:animation
                                forKey:nil];

    self.albumView.frame = frame;
    
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
    
    CGRect hideAlbumLabelViewFrame = self.hideAlbumLabelView.frame;
    float finalX = hideAlbumLabelViewFrame.origin.y + kMVAlbumControlEndMarginFromY;
    float treshholdX = finalX + hideAlbumLabelViewFrame.size.width + finalX;
    hideAlbumLabelViewFrame.origin.x = kMVAlbumControlStartMargin +
                                       (finalX - kMVAlbumControlStartMargin) *
                                       (MIN(translate.x, treshholdX) / treshholdX);
    self.hideAlbumLabelView.frame = hideAlbumLabelViewFrame;
    self.hideAlbumLabelView.hidden = translate.x < 0;
    
    BOOL hideAlbumLabelViewEnabled = (translate.x >= treshholdX && translate.x > 0);
    if(self.hideAlbumLabelView.isEnabled != hideAlbumLabelViewEnabled)
    {
      self.hideAlbumLabelView.enabled = hideAlbumLabelViewEnabled;
      [self.hideAlbumLabelView setNeedsDisplay];
      CATransition *transition = [CATransition animation];
      transition.duration = 0.15f;
      transition.timingFunction = [CAMediaTimingFunction functionWithName:
                                   kCAMediaTimingFunctionEaseInEaseOut];
      transition.type = kCATransitionFade;
      [self.hideAlbumLabelView.layer addAnimation:transition forKey:nil];
    }
    
    CGRect hideArtistLabelViewFrame = self.hideArtistLabelView.frame;
    float beginX = self.frame.size.width - hideArtistLabelViewFrame.size.width -
                   kMVAlbumControlStartMargin;
    finalX = self.frame.size.width -
             (hideArtistLabelViewFrame.origin.y + kMVAlbumControlEndMarginFromY) -
             hideArtistLabelViewFrame.size.width;
    treshholdX = (hideArtistLabelViewFrame.origin.y + kMVAlbumControlEndMarginFromY) * 2 +
                 hideArtistLabelViewFrame.size.width;
    hideArtistLabelViewFrame.origin.x = beginX + (finalX - beginX) *
                                        (MIN(fabs(translate.x), treshholdX) / treshholdX);
    self.hideArtistLabelView.frame = hideArtistLabelViewFrame;
    self.hideArtistLabelView.hidden = translate.x > 0;
    
    BOOL hideArtistLabelViewEnabled = (fabs(translate.x) >= treshholdX && translate.x < 0);
    if(self.hideArtistLabelView.isEnabled != hideArtistLabelViewEnabled)
    {
      self.hideArtistLabelView.enabled = hideArtistLabelViewEnabled;
      [self.hideArtistLabelView setNeedsDisplay];
      CATransition *transition = [CATransition animation];
      transition.duration = 0.15f;
      transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      transition.type = kCATransitionFade;
      [self.hideArtistLabelView.layer addAnimation:transition forKey:nil];
    }
    
    self.layer.zPosition = 1000;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)generateArtworkImageAndDisplay:(BOOL)animated
{
  __strong __block MVAlbumCell *cell = self;
  __strong __block MVAsset *asset = self.artworkAsset;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    UIImage *image = [artworkImagesCache objectForKey:asset.localURL.path];
    if(!image)
    {
      image = [UIImage imageWithContentsOfFile:asset.localURL.path];
      
      CGSize newSize = CGSizeMake(kMVAlbumArtSize, kMVAlbumArtSize);
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
        if(animated)
          cell.artworkView.alpha = 0.0;
        [cell.artworkView setNeedsDisplay];
        if(animated)
          [UIView animateWithDuration:0.2 animations:^{
            cell.artworkView.alpha = 1.0;
          }];
      });
    }
  });
}

@end
