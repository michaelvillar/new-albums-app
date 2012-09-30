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

static NSLock *artworkImagesCacheDictionaryLock = nil;
static NSMutableDictionary *artworkImagesCacheDictionary = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumCell ()

@property (strong, readwrite) MVAsset *artworkAsset;
@property (strong, readwrite) UIImage *artworkImage;
@property (strong, readwrite) MVView *albumView;

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
            albumView     = albumView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)initialize
{
  if(!artworkImagesCacheDictionary)
    artworkImagesCacheDictionary = [NSMutableDictionary dictionary];
  if(!artworkImagesCacheDictionaryLock)
    artworkImagesCacheDictionaryLock = [[NSLock alloc] init];
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

    self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    albumView_ = [[MVView alloc] initWithFrame:self.contentView.bounds];
    albumView_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight;
    albumView_.drawBlock = ^(UIView *view, CGContextRef ctx)
    {
      if(!cell.album)
        return;
      if(!cell.artworkAsset)
      {
        NSURL *url = [NSURL URLWithString:cell.album.artworkUrl];
        cell.artworkAsset = [[MVAssetsManager sharedAssetsManager] assetForRemoteURL:url];
        [cell.artworkAsset addObserver:cell forKeyPath:@"existing" options:0 context:NULL];
        if(cell.artworkAsset.isExisting)
        {
          [artworkImagesCacheDictionaryLock lock];
          cell.artworkImage = [artworkImagesCacheDictionary valueForKey:cell.artworkAsset.localURL.path];
          [artworkImagesCacheDictionaryLock unlock];
          if(!cell.artworkImage)
            [cell generateArtworkImage];
        }
      }
      
      if(cell.isHighlighted)
        [[UIColor whiteColor] set];
      else
        [[UIColor colorWithRed:0.1451 green:0.1529 blue:0.1765 alpha:1.0000] set];
      [[UIBezierPath bezierPathWithRect:cell.bounds] fill];
      
      float marginLeft = 50 + 3;
      if(cell.isHighlighted)
        [[UIColor colorWithRed:0.1451 green:0.1529 blue:0.1765 alpha:1.0000] set];
      else
        [[UIColor colorWithRed:0.7569 green:0.8000 blue:0.9059 alpha:1.0000] set];
      [cell.album.name drawAtPoint:CGPointMake(marginLeft + 6, 6)
                          forWidth:cell.bounds.size.width - marginLeft - 6 * 2
                          withFont:[UIFont boldSystemFontOfSize:18]
                     lineBreakMode:UILineBreakModeTailTruncation];
      
      if(cell.isHighlighted)
        [[UIColor colorWithRed:0.1451 green:0.1529 blue:0.1765 alpha:1.0000] set];
      else
        [[UIColor colorWithRed:0.4471 green:0.4784 blue:0.5765 alpha:1.0000] set];
      [cell.album.artist.name drawAtPoint:CGPointMake(marginLeft + 6, 27)
                                 forWidth:cell.bounds.size.width - marginLeft - 6 * 2
                                 withFont:[UIFont systemFontOfSize:13]
                            lineBreakMode:UILineBreakModeTailTruncation];
      if(cell.artworkImage)
      {
        [cell.artworkImage drawInRect:CGRectMake(0, 0, 50, 50)];
      }
      
      [[UIColor colorWithRed:0.2863 green:0.3176 blue:0.4196 alpha:0.15] set];
      [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0,
                                                   cell.bounds.size.width, 1)] fill];
      
      [[UIColor colorWithRed:0.1098 green:0.1176 blue:0.1373 alpha:0.79] set];
      [[UIBezierPath bezierPathWithRect:CGRectMake(0, cell.bounds.size.height - 1,
                                                   cell.bounds.size.width, 1)] fill];
      if(!cell.isHighlighted)
      {
        [[UIBezierPath bezierPathWithRect:CGRectMake(49.5, 0,
                                                     1, cell.bounds.size.height)] fill];
      }
      
      NSIndexPath *indexPath = [cell.tableView indexPathForCell:cell];
      NSInteger numberOfRows = [cell.tableView numberOfRowsInSection:indexPath.section];
      if(indexPath.row == numberOfRows - 1)
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
      }
    };
    [self.contentView addSubview:albumView_];
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
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)generateArtworkImage
{
  __strong __block MVAlbumCell *cell = self;
  __strong __block MVAsset *asset = self.artworkAsset;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    [artworkImagesCacheDictionaryLock lock];
    UIImage *image = [artworkImagesCacheDictionary valueForKey:asset.localURL.path];
    [artworkImagesCacheDictionaryLock unlock];
    if(!image)
    {
      image = [UIImage imageWithContentsOfFile:asset.localURL.path];
      
      CGSize newSize = CGSizeMake(100, 100);
      UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
      [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
      UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      
      image = newImage;
      
      if(image)
      {
        [artworkImagesCacheDictionaryLock lock];
        [artworkImagesCacheDictionary setValue:image forKey:asset.localURL.path];
        [artworkImagesCacheDictionaryLock unlock];
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
