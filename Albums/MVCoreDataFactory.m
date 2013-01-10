
//
//  KOSCoreDataFactory.m
//  SyncKit
//
//  Created by Michaël on 10/2/12.
//  Copyright (c) 2012 Kickoff. All rights reserved.
//

#import "MVCoreDataFactory.h"
#import "NSManagedObjectContext+Saving.h"
#import "NSObject+PerformBlockOnThread.h"
#import "MVManagedObjectContext.h"

static MVCoreDataFactory *coreDataFactory;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreDataFactory () <MVManagedObjectContextDelegate>

@property (strong, readwrite, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, readwrite) NSLock *lock;
@property (strong, readwrite) NSManagedObjectContext *streamMoc;
@property (strong, readwrite) NSThread *streamMocThread;
@property (readwrite) BOOL streamMocThreadLoop;
@property (strong, readwrite) NSMutableSet *listeningMOCs;
@property (strong, readwrite) NSMutableDictionary *threadsForMOCs;
@property (strong, readwrite) NSMutableArray *draftMOCsToBeMerged;

- (NSURL *)managedObjectModelURL;
- (NSURL *)persistentStoreCoordinatorURL;
- (NSDictionary *)persistentStoreCoordinatorOptions;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCoreDataFactory

@synthesize persistentStoreCoordinator        = persistentStoreCoordinator_,
            lock                              = lock_,
            streamMoc                         = streamMoc_,
            streamMocThread                   = streamMocThread_,
            streamMocThreadLoop               = streamMocThreadLoop_,
            listeningMOCs                     = listeningMOCs_,
            threadsForMOCs                    = threadsForMOCs_,
            draftMOCsToBeMerged               = draftMOCsToBeMerged_;

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (MVCoreDataFactory*)sharedInstance {
  if(!coreDataFactory)
    coreDataFactory = [[MVCoreDataFactory alloc] init];
  return coreDataFactory;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
  self = [super init];
  if(self) {
    persistentStoreCoordinator_ = nil;
    lock_ = [[NSLock alloc] init];
    streamMocThreadLoop_ = NO;
    streamMoc_ = nil;
    listeningMOCs_ = [NSMutableSet set];
    threadsForMOCs_ = [NSMutableDictionary dictionary];
    draftMOCsToBeMerged_ = [NSMutableArray array];
    streamMocThread_ = nil;
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)createMOC {
  MVManagedObjectContext *moc = [[MVManagedObjectContext alloc] init];
  moc.delegate = self;
  moc.persistentStoreCoordinator = self.persistentStoreCoordinator;
  moc.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
  moc.undoManager = nil;
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(mergeChangesFromNotification:)
             name:NSManagedObjectContextDidSaveNotification object:moc];
  [self.lock lock];
  [self.listeningMOCs addObject:moc];
  [self.threadsForMOCs setObject:[NSThread currentThread]
                          forKey:[NSString stringWithFormat:@"%p", moc]];
  [self.lock unlock];
  return moc;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)createDraftMOC {
  MVManagedObjectContext *moc = [[MVManagedObjectContext alloc] init];
  moc.delegate = self;
  moc.persistentStoreCoordinator = self.persistentStoreCoordinator;
  moc.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
  moc.undoManager = nil;
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(mergeChangesFromNotification:)
             name:NSManagedObjectContextDidSaveNotification object:moc];
  [self.lock lock];
  [self.threadsForMOCs setObject:[NSThread currentThread]
                          forKey:[NSString stringWithFormat:@"%p", moc]];
  [self.lock unlock];
  return moc;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)performBlockAndWaitOnMasterMoc:(void (^)(NSManagedObjectContext* moc))block {
  @synchronized(self) {
    if(!self.streamMocThread) {
      streamMocThread_ = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(streamMocThreadRun:)
                                                   object:nil];
      [streamMocThread_ start];
    }
  }
  while(!self.streamMoc) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
  }
  [self mv_performBlockAndWait:^{
    block(self.streamMoc);
  } onThread:self.streamMocThread];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)streamMocThreadRun:(NSThread*)thread {
  self.streamMocThreadLoop = YES;
  self.streamMoc = [self createMOC];
  while(self.streamMocThreadLoop) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetPSC:(NSPersistentStoreCoordinator *)psc {
  NSArray *persisentStores = psc.persistentStores.copy;
  for (NSPersistentStore *persistentStore in persisentStores) {
    NSError *error;
    [psc removePersistentStore:persistentStore error:&error];
    
    // -- in memory store is for tests
    if (![persistentStore.type isEqualToString:@"InMemory"]) {
      NSString *path = persistentStore.URL.path;
      if (path!=nil && ![path isEqualToString:@""]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
      }
    }
  }
  [self.lock lock];
  MVManagedObjectContext *moc;
  for(moc in self.listeningMOCs)
    moc.delegate = nil;
  [self.listeningMOCs removeAllObjects];
  [self.draftMOCsToBeMerged removeAllObjects];
  self.streamMocThreadLoop = NO;
  self.streamMocThread = nil;
  self.streamMoc = nil;
  [self.lock unlock];
  self.persistentStoreCoordinator = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)assertThreadForMOC:(NSManagedObjectContext*)moc {
  NSThread *shouldBeOnThread = [self.threadsForMOCs objectForKey:[NSString stringWithFormat:@"%p", moc]];
  NSString *desc = [NSString stringWithFormat:
                    @"Should be called on %@ instead of %@",
                    shouldBeOnThread, [NSThread currentThread]];
  NSAssert(shouldBeOnThread == [NSThread currentThread], desc);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL *)managedObjectModelURL {
  NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:@"Model" ofType:@"momd"];
	return [NSURL fileURLWithPath:path];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL *)persistentStoreCoordinatorURL {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                       NSUserDomainMask,
                                                       YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString *filepath = [basePath stringByAppendingPathComponent:@"albums"];
	if(![[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:filepath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
	}
	
	NSString *storeFilePath = [filepath stringByAppendingPathComponent:@"albums.sqlite"];
	return [NSURL fileURLWithPath:storeFilePath];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)persistentStoreCoordinatorOptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
          [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
          nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  [self.lock lock];
  if(!persistentStoreCoordinator_) {
    NSURL *momURL = [self managedObjectModelURL];
    NSURL *pscURL = [self persistentStoreCoordinatorURL];
    NSDictionary *pscOptions = [self persistentStoreCoordinatorOptions];
    NSError *error = nil;
    
    // -- PersistentStoreCoordinator
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc]
                                         initWithManagedObjectModel:mom];
    if(![psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil
                                    URL:pscURL
                                options:pscOptions
                                  error:&error]) {
      NSLog(@"Error while adding persistent store. This is probably a migration issue. %@",error);
    }
    persistentStoreCoordinator_ = psc;
  }
  [self.lock unlock];
  return persistentStoreCoordinator_;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Notifications Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mergeChangesFromNotification:(NSNotification*)notification {
  [self.lock lock];
  NSMutableSet *mocs = self.listeningMOCs.mutableCopy;
  [self.lock unlock];
  [mocs removeObject:notification.object];

  NSMutableArray *objectIDs = [NSMutableArray array];
  NSArray* updatedObjects = [[notification.userInfo objectForKey:@"updated"] allObjects];
  NSManagedObject *updatedObject;
  for(updatedObject in updatedObjects) {
    [objectIDs addObject:updatedObject.objectID];
  }
  
  NSManagedObjectContext *moc;
  for(moc in mocs) {
    NSThread *threadOfMoc = [self.threadsForMOCs objectForKey:[NSString stringWithFormat:@"%p",moc]];
    [self mv_performBlock:^{
      [moc mv_mergeChangesFromContextDidSaveNotification:notification
                                   withUpdatedObjectsIDs:objectIDs];
    } onThread:threadOfMoc];
  }
  
  NSUInteger index = [self.draftMOCsToBeMerged indexOfObject:notification.object];
  // trick to remove only one of the references if multiple
  if(index < self.draftMOCsToBeMerged.count)
    [self.draftMOCsToBeMerged removeObjectAtIndex:index];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVManagedObjectContextDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)managedObjectContextWillSave:(MVManagedObjectContext *)moc {
  [self.draftMOCsToBeMerged addObject:moc];
}

@end
