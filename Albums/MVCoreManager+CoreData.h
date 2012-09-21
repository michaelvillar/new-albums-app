//
//  MVCoreManager+CoreData.h
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "MVCoreManager.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreManager (CoreData)

- (NSURL *)managedObjectModelURL;
- (NSURL *)persistentStoreCoordinatorURL;
- (NSDictionary *)persistentStoreCoordinatorOptions;
- (NSManagedObjectContext *)setupMasterMoc;
- (NSManagedObjectContext *)setupUIMocWithMasterMoc:(NSManagedObjectContext *)masterMoc;
- (void)resetPSC:(NSPersistentStoreCoordinator *)psc;

@end
