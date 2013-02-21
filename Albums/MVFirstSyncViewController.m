//
//  MVFirstSyncViewController.m
//  Albums
//
//  Created by Michaël Villar on 2/21/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import "MVFirstSyncViewController.h"
#import "MVContextSource.h"
#import "MVCoreManager.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFirstSyncViewController ()

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;

@property (strong, readwrite) UIImageView *iconImageView;
@property (strong, readwrite) UILabel *headLabel;
@property (strong, readwrite) UILabel *descriptionLabel;
@property (strong, readwrite) UIProgressView *progressView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVFirstSyncViewController

// -- Private
@synthesize coreManager               = coreManager_,
            contextSource             = contextSource_,
            iconImageView             = iconImageView_,
            headLabel                 = headLabel_,
            descriptionLabel          = descriptionLabel_,
            progressView              = progressView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
{
  self = [super init];
  if(self)
  {
    contextSource_ = contextSource;
    coreManager_ = coreManager;
    iconImageView_ = nil;
    headLabel_ = nil;
    descriptionLabel_ = nil;
    progressView_ = nil;
    
    [coreManager_ addObserver:self forKeyPath:@"stepProgression" options:0 context:NULL];
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [coreManager_ removeObserver:self forKeyPath:@"stepProgression"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
  self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view.backgroundColor = [UIColor colorWithRed:0.9129 green:0.9129 blue:0.9129 alpha:1.0000];
  self.view.layer.cornerRadius = 8.0;
  
  float startY = roundf(self.view.frame.size.height / 4.06);
  
  UIImage *iconImage = [UIImage imageNamed:@"flat_icon"];
  self.iconImageView = [[UIImageView alloc] initWithImage:iconImage];
  self.iconImageView.frame = CGRectMake(CGRectGetMidX(self.view.frame) -
                                        CGRectGetWidth(self.iconImageView.frame) / 2,
                                        startY,
                                        self.iconImageView.frame.size.width,
                                        self.iconImageView.frame.size.height);
  self.iconImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                        UIViewAutoresizingFlexibleRightMargin;
  [self.view addSubview:self.iconImageView];
  
  self.headLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, startY + 70 - 17 / 2,
                                                             CGRectGetWidth(self.view.frame) - 60,
                                                             40)];
  self.headLabel.text = NSLocalizedString(@"Syncing Albums…", @"Syncing Albums Heading");
  self.headLabel.textColor = [UIColor colorWithRed:0.1961 green:0.1961 blue:0.1961 alpha:1];
  self.headLabel.textAlignment = NSTextAlignmentCenter;
  self.headLabel.backgroundColor = [UIColor clearColor];
  self.headLabel.opaque = NO;
  self.headLabel.font = [UIFont boldSystemFontOfSize:19];
  self.headLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin;
  [self.view addSubview:self.headLabel];
  
  self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, startY + 110 - 10.5,
                                                                    CGRectGetWidth(self.view.frame) - 60,
                                                                    200)];
  self.descriptionLabel.text = NSLocalizedString(@"Your Music Library is being browsed to \
find albums you might enjoy", @"Syncing Description");
  self.descriptionLabel.textColor = [UIColor colorWithRed:0.4196 green:0.4196 blue:0.4196 alpha:1];
  self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
  self.descriptionLabel.backgroundColor = [UIColor clearColor];
  self.descriptionLabel.opaque = NO;
  self.descriptionLabel.font = [UIFont systemFontOfSize:15];
  self.descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                           UIViewAutoresizingFlexibleRightMargin;
  self.descriptionLabel.numberOfLines = 0;
  [self.descriptionLabel sizeToFit];
  [self.view addSubview:self.descriptionLabel];
  
  CGRect progressViewFrame = CGRectMake((CGRectGetWidth(self.view.frame) - 159) / 2,
                                        CGRectGetMaxY(self.descriptionLabel.frame) + 4 + 8,
                                        159, 40);
  self.progressView = [[UIProgressView alloc] initWithFrame:progressViewFrame];
  
  UIImage *trackImage = [UIImage imageNamed:@"progress_bar_track"];
  trackImage = [trackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
  self.progressView.trackImage = trackImage;
  
  UIImage *progressImage = [UIImage imageNamed:@"progress_bar_progress"];
  progressImage = [progressImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
  self.progressView.progressImage = progressImage;
  self.progressView.progress = 0.0;
  self.progressView.frame = progressViewFrame;
  [self.view addSubview:self.progressView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KVO

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
  if(object == self.coreManager)
  {
    self.progressView.progress = self.coreManager.progression;
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
