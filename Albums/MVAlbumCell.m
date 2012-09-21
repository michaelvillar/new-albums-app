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

static NSLock *artworkImagesCacheDictionaryLock = nil;
static NSMutableDictionary *artworkImagesCacheDictionary = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumCell ()

@property (strong, readwrite) MVAsset *artworkAsset;
@property (strong, readwrite) UIImage *artworkImage;

- (void)generateArtworkImage;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumCell

@synthesize tableView     = tableView_,
            album         = album_,
            artworkAsset  = artworkAsset_,
            artworkImage  = artworkImage_;

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
  if(!self.album)
    return;
  if(!self.artworkAsset)
  {
    NSURL *url = [NSURL URLWithString:self.album.artworkUrl];
    self.artworkAsset = [[MVAssetsManager sharedAssetsManager] assetForRemoteURL:url];
    [self.artworkAsset addObserver:self forKeyPath:@"existing" options:0 context:NULL];
    if(self.artworkAsset.isExisting)
    {
      [artworkImagesCacheDictionaryLock lock];
      self.artworkImage = [artworkImagesCacheDictionary valueForKey:self.artworkAsset.localURL.path];
      [artworkImagesCacheDictionaryLock unlock];
      if(!self.artworkImage)
        [self generateArtworkImage];
    }
  }
  float marginLeft = 43 + 2;
  [[UIColor blackColor] set];
  [self.album.name drawAtPoint:CGPointMake(marginLeft + 6, 4)
                      forWidth:self.bounds.size.width - marginLeft - 6 * 2
                      withFont:[UIFont systemFontOfSize:[UIFont labelFontSize]]
                 lineBreakMode:UILineBreakModeTailTruncation];
  
  [[UIColor grayColor] set];
  [self.album.artist.name drawAtPoint:CGPointMake(marginLeft + 6, 23)
                             forWidth:self.bounds.size.width - marginLeft - 6 * 2
                             withFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]
                        lineBreakMode:UILineBreakModeTailTruncation];
  if(self.artworkImage)
  {
    [self.artworkImage drawInRect:CGRectMake(0, 0, 43, 43)];
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
    [artworkImagesCacheDictionaryLock lock];
    UIImage *image = [artworkImagesCacheDictionary valueForKey:asset.localURL.path];
    [artworkImagesCacheDictionaryLock unlock];
    if(!image)
    {
      image = [UIImage imageWithContentsOfFile:asset.localURL.path];
      
      CGSize newSize = CGSizeMake(43, 43);
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
