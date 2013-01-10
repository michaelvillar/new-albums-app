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
                                      NSFetchedResultsControllerDelegate,
                                      MVAlbumCellDelegate>

@property (strong, readwrite) UITableView *tableView;
@property (strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (strong, readwrite) NSDateFormatter *sectionDateFormatter;
@property (strong, readwrite) MVView *roundedTopCorners;
@property (strong, readwrite) MVView *roundedBottomCorners;
@property (strong, readwrite) MVLoadingView *loadingView;
@property (strong, readwrite) MVCoreManager *coreManager;
@property (readwrite) int type;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;

- (void)reloadTableViewAfterBlock:(void(^)(void))block;
- (void)updateLoadingView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumsViewController

@synthesize tableView                 = tableView_,
            fetchedResultsController  = fetchedResultsController_,
            sectionDateFormatter      = sectionDateFormatter_,
            roundedTopCorners         = roundedTopCorners_,
            roundedBottomCorners      = roundedBottomCorners_,
            loadingView               = loadingView_,
            coreManager               = coreManager_,
            type                      = type_,
            contextSource             = contextSource_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
                coreManager:(MVCoreManager*)coreManager
                       type:(int)type
{
  self = [super init];
  if (self)
  {
    tableView_ = nil;
    contextSource_ = contextSource;
    type_ = type;
    coreManager_ = coreManager;

    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:[MVAlbum entityName]];
    NSSortDescriptor *sortCreatedAt = [[NSSortDescriptor alloc]
                                          initWithKey:@"createdAt"
                                            ascending:NO];
    NSSortDescriptor *sortReleaseDate = [[NSSortDescriptor alloc]
                                         initWithKey:@"releaseDate"
                                           ascending:NO];
    req.sortDescriptors = [NSArray arrayWithObjects:sortCreatedAt, sortReleaseDate, nil];
    req.fetchBatchSize = 20;
    req.predicate = [NSPredicate predicateWithFormat:@"hidden == %d AND artist.hidden == %d",NO,NO];

    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                        managedObjectContext:contextSource.uiMoc
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    fetchedResultsController_.delegate = self;
   
    sectionDateFormatter_ = [[NSDateFormatter alloc] init];
    sectionDateFormatter_.dateFormat = @"MM/dd";
    
    roundedTopCorners_ = nil;
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
  self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view.backgroundColor = [UIColor blackColor];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                style:UITableViewStylePlain];
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.rowHeight = 50.0;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.canCancelContentTouches = NO;
  [self.view addSubview:self.tableView];
  if(self.type == 2)
    [self.tableView setScrollsToTop:NO];
  
  if(!self.roundedTopCorners)
  {
    self.roundedTopCorners = [[MVView alloc] initWithFrame:CGRectMake(0,
                                                                      0,
                                                                      self.view.bounds.size.width,
                                                                      kMVSectionViewRadius)];
    self.roundedTopCorners.autoresizingMask = UIViewAutoresizingNone;
    self.roundedTopCorners.backgroundColor = [UIColor clearColor];
    self.roundedTopCorners.drawBlock = ^(UIView *view, CGContextRef ref)
    {
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, kMVSectionViewRadius)];
      [path addCurveToPoint:CGPointMake(kMVSectionViewRadius, 0)
              controlPoint1:CGPointMake(0, 0)
              controlPoint2:CGPointMake(kMVSectionViewRadius, 0)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVSectionViewRadius, 0)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, kMVSectionViewRadius)
              controlPoint1:CGPointMake(view.frame.size.width, 0)
              controlPoint2:CGPointMake(view.frame.size.width, kMVSectionViewRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width, 0)];
      [path addLineToPoint:CGPointMake(0, 0)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
  }
  [self.view addSubview:self.roundedTopCorners];

  if(!self.roundedBottomCorners)
  {
    self.roundedBottomCorners = [[MVView alloc] initWithFrame:CGRectMake(0,
                                                                         self.view.bounds.size.height -
                                                                         kMVSectionViewRadius,
                                                                         self.view.bounds.size.width,
                                                                         kMVSectionViewRadius)];
    self.roundedBottomCorners.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
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
  
  [super loadView];
  
  [self.fetchedResultsController performFetch:nil];
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [MVAlbumCell rowHeight];
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
  cell.delegate = self;

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
  [self.tableView reloadData];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVAlbumCellDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumCellDidTriggerHideAlbum:(MVAlbumCell *)albumCell
{
  [self reloadTableViewAfterBlock:^{
    MVAlbum *album = albumCell.album;
    album.hiddenValue = YES;
    [self.contextSource.uiMoc mv_save];
  }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)albumCellDidTriggerHideArtist:(MVAlbumCell *)albumCell
{
  [self reloadTableViewAfterBlock:^{
    MVAlbum *album = albumCell.album;
    album.artist.hiddenValue = YES;
    [self.contextSource.uiMoc mv_save];
  }];
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
- (void)reloadTableViewAfterBlock:(void(^)(void))block
{
  NSArray *oldObjects = [NSArray arrayWithArray:self.fetchedResultsController.fetchedObjects];
  self.fetchedResultsController.delegate = nil;
  
  block();
  
  [self.fetchedResultsController performFetch:nil];
  self.fetchedResultsController.delegate = self;
  
  NSMutableArray *indexPathsToDelete = [NSMutableArray array];
  NSMutableArray *indexPathsToInsert = [NSMutableArray array];
  NSIndexPath *indexPath;
  MVAlbum *album;
  NSArray *newObjects = [NSArray arrayWithArray:self.fetchedResultsController.fetchedObjects];
  NSUInteger oldObjectsCount = oldObjects.count;
  NSUInteger newObjectsCount = newObjects.count;
  
  for(NSUInteger i=0;i<oldObjectsCount;i++)
  {
    album = [oldObjects objectAtIndex:i];
    if(![newObjects containsObject:album])
    {
      indexPath = [NSIndexPath indexPathForRow:i inSection:0];
      [indexPathsToDelete addObject:indexPath];
    }
  }
  for(NSUInteger i=0;i<newObjectsCount;i++)
  {
    album = [newObjects objectAtIndex:i];
    if(![oldObjects containsObject:album])
    {
      indexPath = [NSIndexPath indexPathForRow:i inSection:0];
      [indexPathsToInsert addObject:indexPath];
    }
  }
  
  [self.tableView beginUpdates];
  if ([indexPathsToDelete count] > 0) {
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete
                          withRowAnimation:UITableViewRowAnimationBottom];
  }
  if ([indexPathsToInsert count] > 0) {
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert
                          withRowAnimation:UITableViewRowAnimationBottom];
  }
  [self.tableView endUpdates];
  
  NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
  for (NSIndexPath *indexPath in visibleIndexPaths)
  {
    // if first row is visible, layout it
    // (because if the row before it was removed, corners have changed
    if (indexPath.row == 0)
      [[self.tableView cellForRowAtIndexPath:indexPath] setNeedsLayout];
    // if last row is visible, layout it
    // (because if the row after it was removed, corners have changed
    else if (indexPath.row == newObjects.count - 1)
      [[self.tableView cellForRowAtIndexPath:indexPath] setNeedsLayout];
  }
}

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
