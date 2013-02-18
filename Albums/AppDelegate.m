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
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *appStoreCountry = [defaults stringForKey:kMVPreferencesAppStoreCountry];
  if(!appStoreCountry) {
    appStoreCountry = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    [defaults setValue:appStoreCountry forKey:kMVPreferencesAppStoreCountry];
    [defaults synchronize];
  }
  
  self.window = [[MVWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  self.rootViewController = [[MVRootViewController alloc] initWithContextSource:self.coreManager
                                                                    coreManager:self.coreManager];
  self.window.rootViewController = self.rootViewController;
  
  [self.window makeKeyAndVisible];
  
  return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *appStoreCountry = [defaults stringForKey:kMVPreferencesAppStoreCountry];
  self.coreManager.countryCode = appStoreCountry;
  [self.coreManager sync];
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
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVNotificationSyncDidStart
                                                      object:self.coreManager];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)coreManagerDidFinishSync:(MVCoreManager *)coreManager
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVNotificationSyncDidFinish
                                                      object:self.coreManager];
}

@end
