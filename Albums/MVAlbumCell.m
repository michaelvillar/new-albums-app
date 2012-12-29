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

#define kMVAlbumArtSize 50

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
      
      [[UIColor blackColor] set];
      [[UIBezierPath bezierPathWithRect:view.bounds] fill];
      
      float marginLeft = 12 + kMVAlbumArtSize + 3;
      float marginTop = 6;
      CGRect artworkRect = CGRectMake(12, 6, kMVAlbumArtSize, kMVAlbumArtSize);
      
      if(cell.isHighlighted)
        [[UIColor colorWithRed:0.1451 green:0.1529 blue:0.1765 alpha:1.0000] set];
      else
        [[UIColor colorWithRed:0.7569 green:0.8000 blue:0.9059 alpha:1.0000] set];
      
      [[UIColor whiteColor] set];
      [cell.album.shortName drawAtPoint:CGPointMake(marginLeft + 6, marginTop + 6)
                               forWidth:cell.bounds.size.width - marginLeft - 6 * 2 - 12
                               withFont:[UIFont boldSystemFontOfSize:16]
                          lineBreakMode:NSLineBreakByTruncatingMiddle];
      
      [[UIColor colorWithRed:0.8966 green:0.8965 blue:0.8966 alpha:1.0000] set];
      [cell.album.artist.name drawAtPoint:CGPointMake(marginLeft + 6, marginTop + 27)
                                 forWidth:cell.bounds.size.width - marginLeft - 6 * 2 - 12
                                 withFont:[UIFont systemFontOfSize:13]
                            lineBreakMode:NSLineBreakByTruncatingMiddle];
      if(cell.artworkImage)
      {
        [cell.artworkImage drawInRect:artworkRect];
      }
      
      if(cell.isHighlighted)
      {
        [[UIColor colorWithWhite:0 alpha:0.5] set];
        [[UIBezierPath bezierPathWithRect:artworkRect] fill];
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
      
      CGSize newSize = CGSizeMake(kMVAlbumArtSize * 2, kMVAlbumArtSize * 2);
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
