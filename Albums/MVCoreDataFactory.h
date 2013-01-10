//
//  KOSCoreDataFactory.h
//  SyncKit
//
//  Created by Michaël on 10/2/12.
//  Copyright (c) 2012 Kickoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVCoreDataFactory : NSObject

+ (MVCoreDataFactory*)sharedInstance;
- (NSManagedObjectContext *)createMOC;
- (NSManagedObjectContext *)createDraftMOC;
- (void)performBlockAndWaitOnMasterMoc:(void (^)(NSManagedObjectContext* moc))block;
- (void)resetPSC:(NSPersistentStoreCoordinator *)psc;
- (void)assertThreadForMOC:(NSManagedObjectContext*)moc;

@end
