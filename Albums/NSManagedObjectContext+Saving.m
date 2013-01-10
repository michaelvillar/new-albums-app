//
//  NSManagedObjectContext+Saving.m
//  SyncKit
//
//  Created by Thomas Balthazar on 15/01/12.
//  Copyright (c) 2012 Kickoff. All rights reserved.
//

#import "NSManagedObjectContext+Saving.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSManagedObjectContext (Saving)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mv_save
{
	NSError *error;
	BOOL r = [self save:&error];
  if(!r)
    NSLog(@"Save error on context: %@\n%@", [error localizedDescription], [error userInfo]);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mv_mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
                                withUpdatedObjectsIDs:(NSArray*)updatedObjectsIDS {
  // Fault in all updated objects
  NSManagedObjectID *updatedObjectID;
  for (updatedObjectID in updatedObjectsIDS)
  {
    [[self objectWithID:updatedObjectID] willAccessValueForKey:nil];
  }
  
  [self mergeChangesFromContextDidSaveNotification:notification];
}

@end
