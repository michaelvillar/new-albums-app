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
#import "MVView.h"
#import "MVLoadingCell.h"
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
@property (strong, readwrite) MVCoreManager *coreManager;
@property (readwrite) BOOL showsLoadingCell;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;

- (void)reloadTableViewAfterBlock:(void(^)(void))block;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumsViewController

// -- Private
@synthesize tableView                 = tableView_,
            fetchedResultsController  = fetchedResultsController_,
            sectionDateFormatter      = sectionDateFormatter_,
            roundedTopCorners         = roundedTopCorners_,
            roundedBottomCorners      = roundedBottomCorners_,
            coreManager               = coreManager_,
            showsLoadingCell          = showsLoadingCell_,
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
    showsLoadingCell_ = NO;
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
    req.predicate = [NSPredicate predicateWithFormat:
                     @"hidden == %d AND \
                     artist.hidden == %d AND \
                     releaseDate >= %@",
                     NO, NO, [NSDate dateWithTimeIntervalSinceNow:- 2 * 30 * 24 * 3600]];

    fetchedResultsController_ = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                        managedObjectContext:contextSource.uiMoc
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    fetchedResultsController_.delegate = self;
   
    sectionDateFormatter_ = [[NSDateFormatter alloc] init];
    sectionDateFormatter_.dateFormat = @"MM/dd";
    
    roundedTopCorners_ = nil;
    roundedBottomCorners_ = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidStart:)
                                                 name:kMVNotificationSyncDidStart
                                               object:self.coreManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncProgress:)
                                                 name:kMVNotificationSyncDidProgress
                                               object:self.coreManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidFinish:)
                                                 name:kMVNotificationSyncDidFinish
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
  
  if(!self.roundedTopCorners)
  {
    self.roundedTopCorners = [[MVView alloc] initWithFrame:CGRectMake(0,
                                                                      0,
                                                                      self.view.bounds.size.width,
                                                                      kMVCellRadius)];
    self.roundedTopCorners.autoresizingMask = UIViewAutoresizingNone;
    self.roundedTopCorners.backgroundColor = [UIColor clearColor];
    self.roundedTopCorners.drawBlock = ^(UIView *view, CGContextRef ref)
    {
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, kMVCellRadius)];
      [path addCurveToPoint:CGPointMake(kMVCellRadius, 0)
              controlPoint1:CGPointMake(0, 0)
              controlPoint2:CGPointMake(kMVCellRadius, 0)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVCellRadius, 0)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, kMVCellRadius)
              controlPoint1:CGPointMake(view.frame.size.width, 0)
              controlPoint2:CGPointMake(view.frame.size.width, kMVCellRadius)];
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
                                                                         kMVCellRadius,
                                                                         self.view.bounds.size.width,
                                                                         kMVCellRadius)];
    self.roundedBottomCorners.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.roundedBottomCorners.backgroundColor = [UIColor clearColor];
    self.roundedBottomCorners.drawBlock = ^(UIView *view, CGContextRef ref)
    {
      UIBezierPath *path = [UIBezierPath bezierPath];
      [path moveToPoint:CGPointMake(0, 0)];
      [path addCurveToPoint:CGPointMake(kMVCellRadius, kMVCellRadius)
              controlPoint1:CGPointMake(0, kMVCellRadius)
              controlPoint2:CGPointMake(kMVCellRadius, kMVCellRadius)];
      [path addLineToPoint:CGPointMake(view.frame.size.width - kMVCellRadius, kMVCellRadius)];
      [path addCurveToPoint:CGPointMake(view.frame.size.width, 0)
              controlPoint1:CGPointMake(view.frame.size.width, kMVCellRadius)
              controlPoint2:CGPointMake(view.frame.size.width, 0)];
      [path addLineToPoint:CGPointMake(view.frame.size.width, kMVCellRadius + 1)];
      [path addLineToPoint:CGPointMake(0, kMVCellRadius + 1)];
      [path closePath];
      
      [[UIColor blackColor] set];
      [path fill];
    };
  }
  [self.view addSubview:self.roundedBottomCorners];
  
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
  NSInteger rows =  [[[self.fetchedResultsController sections] objectAtIndex:section]
                     numberOfObjects];
  if(self.showsLoadingCell)
    rows += 1;
  return rows;
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
  if(self.showsLoadingCell && indexPath.row == 0)
  {
    NSString *loadingCellIdentifier = @"loadingCellIdentifier";
    MVLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
    if(!cell)
    {
      cell = [[MVLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:loadingCellIdentifier];
    }
    return cell;
  }
  
  NSString *cellIdentifier = @"cellIdentifier";
  
  MVAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if(!cell)
  {
    cell = [[MVAlbumCell alloc] initWithStyle:UITableViewCellStyleDefault
                              reuseIdentifier:cellIdentifier];
    cell.tableView = tableView;
  }
  cell.delegate = self;

  if(self.showsLoadingCell ||
     indexPath.row > self.fetchedResultsController.fetchedObjects.count - 1)
  {
    indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1
                                   inSection:indexPath.section];
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
- (void)syncDidStart:(NSNotification*)notification
{
  if(!self.showsLoadingCell && self.coreManager.isSyncing)
  {
    self.showsLoadingCell = self.coreManager.isSyncing;
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:
                                            [NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)syncDidFinish:(NSNotification*)notification
{
  if(self.showsLoadingCell && !self.coreManager.isSyncing)
  {
    self.showsLoadingCell = self.coreManager.isSyncing;
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:
                                            [NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)syncProgress:(NSNotification*)notification
{}

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

@end
