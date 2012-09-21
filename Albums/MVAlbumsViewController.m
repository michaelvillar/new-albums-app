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

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVAlbumsViewController () <UITableViewDataSource,
                                      UITableViewDelegate,
                                      NSFetchedResultsControllerDelegate>

@property (strong, readwrite) UITableView *tableView;
@property (strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (strong, readwrite) NSMutableArray *sections;
@property (strong, readwrite) NSObject<MVContextSource> *contextSource;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVAlbumsViewController

@synthesize tableView       = tableView_,
            fetchedResultsController = fetchedResultsController_,
            contextSource   = contextSource_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithContextSource:(NSObject<MVContextSource>*)contextSource
{
    self = [super init];
    if (self)
    {
      tableView_ = nil;
      contextSource_ = contextSource;

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
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView
{
  [self.fetchedResultsController performFetch:nil];

  self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view.backgroundColor = [UIColor blackColor];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                style:UITableViewStylePlain];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.view addSubview:self.tableView];
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)indexPath
{
  NSObject <NSFetchedResultsSectionInfo> *section = [self.fetchedResultsController.sections
                                                     objectAtIndex:indexPath];
  return section.name.copy;
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

@end
