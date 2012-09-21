//
//  MVCoreManager+CoreData.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVCoreManager+CoreData.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVCoreManager (CoreData)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL *)managedObjectModelURL
{
  NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:@"Model" ofType:@"momd"];
	return [NSURL fileURLWithPath:path];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSURL *)persistentStoreCoordinatorURL
{
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
- (NSDictionary *)persistentStoreCoordinatorOptions
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
          [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
          nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)setupMasterMoc
{
  NSURL *momURL = [self managedObjectModelURL];
  NSURL *pscURL = [self persistentStoreCoordinatorURL];
  NSDictionary *pscOptions = [self persistentStoreCoordinatorOptions];
  NSError *error = nil;
  
  // -- PersistentStoreCoordinator
  NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
  NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc]
                                       initWithManagedObjectModel:mom];
  [psc addPersistentStoreWithType:NSSQLiteStoreType
                    configuration:nil
                              URL:pscURL
                          options:pscOptions
                            error:&error];
  
  // -- masterMoc (connected to PSC, private)
  NSManagedObjectContext *moc = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  moc.persistentStoreCoordinator = psc;
  
  return moc;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)setupUIMocWithMasterMoc:(NSManagedObjectContext *)masterMoc
{
  // -- uiMoc (readonly, public)
  NSManagedObjectContext *moc = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
  moc.parentContext = masterMoc;
  
  return moc;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetPSC:(NSPersistentStoreCoordinator *)psc
{
  for (NSPersistentStore *persistentStore in psc.persistentStores) {
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
}

@end
