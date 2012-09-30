//
//  MVAlbumsViewController.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVAlbumsViewController.h"
#import "MVContextSource.h"
#import "MVAlbum.h"
#import "MVArtist.h"
#import "MVAlbumCell.h"
#import "MVSectionView.h"
#import "MVView.h"
#import "MVLoadingView.h"
#import "MVCoreManager.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumsViewController () <UITableViewDataSource,
                                      UITableViewDelegate,
                                      NSFetchedResultsControllerDelegate>

@property (strong, readwrite) UITableView *tableView;
@property (strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (strong, readwrite) NSDateFormatter *sectionDateFormatter;
@property (strong, readwrite) MVView *roundedBottomCorners;
@property (strong, readwrite) MVLoadingView *loadingView;
@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;

- (void)updateLoadingView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumsViewController

@synthesize tableView                 = tableView_,
            fetchedResultsController  = fetchedResultsController_,
            sectionDateFormatter      = sectionDateFormatter_,
            roundedBottomCorners      = roundedBottomCorners_,
            loadingView               = loadingView_,
            coreManager               = coreManager_,
            contextSource             = contextSource_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
{
    self = [super init];
    if (self)
    {
      tableView_ = nil;
      contextSource_ = contextSource;
      coreManager_ = coreManager;

      NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVAlbum entityName]];
      NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                                initWithKey:@"releaseDate" ascending:NO];
      req.sortDescriptors = [NSArray arrayWithObject:sort];
      req.predicate = [NSPredicate predicateWithFormat:
                       @"releaseDate > %@",
                       [NSDate dateWithTimeIntervalSinceNow:- 365 * 24 * 3600]];

      fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                          managedObjectContext:contextSource.uiMoc
                                                                        sectionNameKeyPath:@"releaseDate"
                                                                                 cacheName:@"Albums"];
      fetchedResultsController_.delegate = self;
      
      sectionDateFormatter_ = [[NSDateFormatter alloc] init];
      sectionDateFormatter_.dateFormat = @"d MMM YYYY";
      
      roundedBottomCorners_ = nil;
      loadingView_ = nil;
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncProgress:)
                                                   name:kMVNotificationSyncDidProgress
                                                 object:self.coreManager];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView
{
  [self.fetchedResultsController performFetch:nil];

  self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view.backgroundColor = [UIColor blackColor];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                style:UITableViewStylePlain];
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.rowHeight = 50.0;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.view addSubview:self.tableView];
  
  if(!self.roundedBottomCorners)
  {
    self.roundedBottomCorners = [[MVView alloc] initWithFrame:CGRectMake(0,
                                                                         self.view.bounds.size.height -
                                                                         kMVSectionViewRadius,
                                                                         self.view.bounds.size.width,
                                                                         kMVSectionViewRadius)];
    self.roundedBottomCorners.backgroundColor = [UIColor clearColor];
    self.roundedBottomCorners.drawBlock = ^(UIView *view, CGContextRef ref)
    {
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, 0)];
      [path addCurveToPoint:CGPointMake(kMVSectionViewRadius, kMVSectionViewRadius)
              controlPoint1:CGPointMake(0, kMVSectionViewRadius)
              controlPoint2:CGPointMake(kMVSectionViewRadius, kMVSectionViewRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVSectionViewRadius, kMVSectionViewRadius)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, 0)
              controlPoint1:CGPointMake(view.frame.size.width, kMVSectionViewRadius)
              controlPoint2:CGPointMake(view.frame.size.width, 0)];
      [path addLineToPoint:CGPointMake(view.frame.size.width, kMVSectionViewRadius + 1)];
      [path addLineToPoint:CGPointMake(0, kMVSectionViewRadius + 1)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
  }
  [self.view addSubview:self.roundedBottomCorners];

  [self updateLoadingView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
  [super viewDidLoad];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload
{
  [super viewDidUnload];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  MVAlbum *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:album.iTunesStoreUrl]];
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  NSObject <NSFetchedResultsSectionInfo> *sectionInfo = [self.fetchedResultsController.sections
                                                         objectAtIndex:section];
  
  MVSectionView* sectionView = [[MVSectionView alloc] initWithFrame:CGRectMake(0, 0,
                                                                               tableView.bounds.size.width,
                                                                               48)];
  NSArray *objects = sectionInfo.objects;
  if(objects.count > 0)
  {
    MVAlbum *album = [objects objectAtIndex:0];
    sectionView.label = [self.sectionDateFormatter stringFromDate:album.releaseDate];
  }
  return sectionView;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 48;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.fetchedResultsController.sections.count;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  static NSString *cellIdentifier = @"AlbumCell";
  
  MVAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if(!cell)
  {
    cell = [[MVAlbumCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                              reuseIdentifier:cellIdentifier];
    cell.tableView = tableView;
  }

  MVAlbum *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.album = album;
  [cell setNeedsDisplay];
  return cell;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  return [NSArray array];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{

}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  NSLog(@"reload data!");
  [self.tableView reloadData];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Notifications Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)syncProgress:(NSNotification*)notification
{
  [self updateLoadingView];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateLoadingView
{
  BOOL visible = self.coreManager.isSyncing;
  if(visible)
  {
    if(!self.loadingView)
    {
      float height = 70;
      float y = roundf((self.view.bounds.size.height - height) / 2);
      self.loadingView = [[MVLoadingView alloc] initWithFrame:CGRectMake(25, y,
                                                                         self.view.bounds.size.width
                                                                         - 25 * 2, height)];
    }
    
    NSMutableString *label = [NSMutableString string];
    if(self.coreManager.step == kMVCoreManagerStepSearchingArtistIds)
    {
      [label appendString:NSLocalizedString(@"Syncing Artists",@"Loading")];
      if(self.coreManager.stepProgression > 0)
        [label appendFormat:@" (%i%%)",(int)(self.coreManager.stepProgression * 100)];
    }
    else if(self.coreManager.step == kMVCoreManagerStepSearchingNewAlbums)
    {
      [label appendString:NSLocalizedString(@"Syncing Albums",@"Loading")];
      if(self.coreManager.stepProgression > 0)
        [label appendFormat:@" (%i%%)",(int)(self.coreManager.stepProgression * 100)];
    }
    else
      [label appendString:NSLocalizedString(@"Loading",@"Loading")];
    
    self.loadingView.label = label;
    [self.loadingView setNeedsDisplay];
    
    [self.view addSubview:self.loadingView];
  }
  else
    [self.loadingView removeFromSuperview];
}

@end
