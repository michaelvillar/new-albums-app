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
#import "MVStatusBarOverlay.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AppDelegate () <MVCoreManagerDelegate>

@property (strong, readwrite) MVCoreManager *coreManager;
@property (strong, nonatomic) MVRootViewController *rootViewController;
@property (strong, readwrite) MVStatusBarOverlay *statusBarView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AppDelegate

@synthesize coreManager       = coreManager_,
            statusBarView     = statusBarView_;

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
  
  NSArray *availableCountries = [NSArray arrayWithObjects:@"AL",@"DZ",@"AO",@"AI",@"AG",@"AR",
                                 @"AM",@"AU",@"AT",@"AZ",@"BS",@"BH",@"BB",@"BY",@"BE",@"BZ",
                                 @"BJ",@"BM",@"BT",@"BO",@"BW",@"BR",@"VG",@"BN",@"BG",@"BF",
                                 @"KH",@"CA",@"CV",@"KY",@"TD",@"CL",@"CN",@"CO",@"CG",@"CR",
                                 @"HR",@"CY",@"CZ",@"DK",@"DM",@"DO",@"EC",@"EG",@"SV",@"EE",
                                 @"FJ",@"FI",@"FR",@"GM",@"DE",@"GH",@"GR",@"GD",@"GT",@"GW",
                                 @"GY",@"HN",@"HK",@"HU",@"IS",@"IN",@"ID",@"IE",@"IL",@"IT",
                                 @"JM",@"JP",@"JO",@"KZ",@"KE",@"KW",@"KG",@"LA",@"LV",@"LB",
                                 @"LR",@"LT",@"LU",@"MO",@"MK",@"MG",@"MW",@"MY",@"ML",@"MT",
                                 @"MR",@"MU",@"MX",@"FM",@"MN",@"MS",@"MD",@"MZ",@"NA",@"NP",
                                 @"NL",@"NZ",@"NI",@"NE",@"NG",@"NO",@"OM",@"PK",@"PW",@"PA",
                                 @"PG",@"PY",@"PE",@"PH",@"PL",@"PT",@"QA",@"RO",@"RU",@"KN",
                                 @"LC",@"VC",@"ST",@"SA",@"SN",@"SC",@"SL",@"SG",@"SK",@"SI",
                                 @"SB",@"ZA",@"KR",@"ES",@"LK",@"SR",@"SZ",@"SE",@"CH",@"TW",
                                 @"TJ",@"TZ",@"TH",@"TT",@"TN",@"TR",@"TM",@"TC",@"UG",@"UA",
                                 @"AE",@"GB",@"US",@"UY",@"UZ",@"VE",@"VN",@"YE",@"ZW",nil];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *appStoreCountry = [defaults stringForKey:kMVPreferencesAppStoreCountry];
  if(!appStoreCountry) {
    NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
    NSArray *localeIdentifierArr = [localeIdentifier componentsSeparatedByString:@"_"];
    if(localeIdentifierArr.count > 1) {
      appStoreCountry = [[localeIdentifierArr objectAtIndex:1] uppercaseString];
      if(![availableCountries containsObject:appStoreCountry])
        appStoreCountry = nil;
    }

    if(!appStoreCountry)
      appStoreCountry = @"US";
    [defaults setValue:appStoreCountry forKey:kMVPreferencesAppStoreCountry];
    [defaults synchronize];
  }

  self.window = [[MVWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  
  self.rootViewController = [[MVRootViewController alloc] initWithContextSource:self.coreManager
                                                                    coreManager:self.coreManager];
  self.window.rootViewController = self.rootViewController;
  
  [self.window makeKeyAndVisible];
  
  self.statusBarView = [[MVStatusBarOverlay alloc] init];
  
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
    if(self.coreManager.hasSyncedAtLeastOnce)
    {
      self.statusBarView.text = [NSString stringWithFormat:
                                 NSLocalizedString(@"Synchronizing (%i%%)…",
                                                   @"Sync progress status bar label"),
                                 (int)(round(self.coreManager.progression * 100))];
    }
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
  if(self.coreManager.hasSyncedAtLeastOnce)
  {
    self.statusBarView.text = NSLocalizedString(@"Synchronizing…", @"Sync status bar label");
    [self.statusBarView setOverlayHidden:NO animated:YES];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVNotificationSyncDidStart
                                                      object:self.coreManager];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)coreManagerDidFinishSync:(MVCoreManager *)coreManager
{
  if(self.coreManager.hasSyncedAtLeastOnce)
  {
    self.statusBarView.text = NSLocalizedString(@"Done", @"Finished sync status bar label");
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.statusBarView setOverlayHidden:YES animated:YES];
    });
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:kMVNotificationSyncDidFinish
                                                      object:self.coreManager];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)coreManagerDidFailToSync:(MVCoreManager *)coreManager
{
  if(self.coreManager.hasSyncedAtLeastOnce)
  {
    self.statusBarView.text = NSLocalizedString(@"Failed to sync", @"Failed sync status bar label");
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.statusBarView setOverlayHidden:YES animated:YES];
    });
  }
}

@end
