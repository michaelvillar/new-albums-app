//
//  MVPlaceholderView.m
//  Albums
//
//  Created by Michaël Villar on 2/26/13.
//  Copyright (c) 2013 Michael Villar. All rights reserved.
//

#import "MVPlaceholderView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVPlaceholderView ()

@property (strong, readwrite) UIImageView *iconImageView;
@property (strong, readwrite) UILabel *headLabel;
@property (strong, readwrite) UILabel *descriptionLabel;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVPlaceholderView

// -- Private
@synthesize iconImageView           = iconImageView_,
            headLabel               = headLabel_,
            descriptionLabel        = descriptionLabel_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    float startY = roundf(self.frame.size.height / 4.06);
    
    UIImage *iconImage = [UIImage imageNamed:@"white_flat_icon"];
    self.iconImageView = [[UIImageView alloc] initWithImage:iconImage];
    self.iconImageView.frame = CGRectMake(CGRectGetMidX(self.frame) -
                                          CGRectGetWidth(self.iconImageView.frame) / 2,
                                          startY,
                                          self.iconImageView.frame.size.width,
                                          self.iconImageView.frame.size.height);
    self.iconImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:self.iconImageView];
    
    self.headLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, startY + 70 - 17 / 2,
                                                               CGRectGetWidth(self.frame) - 60,
                                                               40)];
    self.headLabel.text = NSLocalizedString(@"No Album",
                                            @"Blank state head title");
    self.headLabel.textColor = [UIColor colorWithRed:0.9059 green:0.9059 blue:0.9059 alpha:1];
    self.headLabel.textAlignment = NSTextAlignmentCenter;
    self.headLabel.backgroundColor = [UIColor clearColor];
    self.headLabel.opaque = NO;
    self.headLabel.font = [UIFont boldSystemFontOfSize:19];
    self.headLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                      UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:self.headLabel];

    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, startY + 110 - 10.5,
                                                                      CGRectGetWidth(self.frame) - 60,
                                                                      200)];
    self.descriptionLabel.text = NSLocalizedString(@"You should add some songs to your device so \
we can figure out your favorite artists", @"Blank state description");
    self.descriptionLabel.textColor = [UIColor colorWithRed:0.7490 green:0.7490 blue:0.7490 alpha:1];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.backgroundColor = [UIColor clearColor];
    self.descriptionLabel.opaque = NO;
    self.descriptionLabel.font = [UIFont systemFontOfSize:15];
    self.descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                             UIViewAutoresizingFlexibleRightMargin;
    self.descriptionLabel.numberOfLines = 0;
    [self.descriptionLabel sizeToFit];
    [self addSubview:self.descriptionLabel];
  }
  return self;
}

@end
