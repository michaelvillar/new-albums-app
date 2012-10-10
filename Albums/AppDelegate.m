//
//  AppDelegate.m
//  Albums
//
//  Created by Michaël on 9/16/12.
//  Copyright (c) 2012 Michael Villar. All rights reserved.
//

#import "AppDelegate.h"
#import "MVAlbumsViewController.h"
#import "MVRootViewController.h"
#import "MVCoreManager.h"
#import "MVWindow.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AppDelegate () <MVCoreManagerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, nonatomic) MVRootViewController *rootViewController;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AppDelegate

@synthesize coreManager       = coreManager_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if(self)
  {
    coreManager_ = [[MVCoreManager alloc] init];
    coreManager_.delegate = self;
    [coreManager_ addObserver:self forKeyPath:@"step" options:0 context:NULL];
    [coreManager_ addObserver:self forKeyPath:@"stepProgression" options:0 context:NULL];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(masterMocDidSave:)
               name:NSManagedObjectContextDidSaveNotification object:nil];
  }
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [coreManager_ removeObserver:self forKeyPath:@"step"];
  [coreManager_ removeObserver:self forKeyPath:@"stepProgression"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
  
  [self.coreManager sync];

  self.window = [[MVWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  self.rootViewController = [[MVRootViewController alloc] initWithContextSource:self.coreManager
                                                                    coreManager:self.coreManager];
  self.window.rootViewController = self.rootViewController;
  
  [self.window makeKeyAndVisible];
  
  return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Notification Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)masterMocDidSave:(NSNotification*)notification
{
  if(notification.object != self.coreManager.masterMoc)
    return;
  [self.coreManager.uiMoc performBlock:^{
    [self.coreManager.uiMoc mergeChangesFromContextDidSaveNotification:notification];
  }];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark KVO Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if(object == self.coreManager)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMVNotificationSyncDidProgress
                                                        object:self.coreManager];
  }
  else
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVCoreManagerDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)coreManagerDidStartSync:(MVCoreManager *)coreManager
{
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)coreManagerDidFinishSync:(MVCoreManager *)coreManager
{
}

@end
