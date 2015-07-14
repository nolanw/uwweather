//
//  UWWeatherAppDelegate.h
//  UWWeather
//
//  Created by Nolan Waite on 09-12-03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

@class UWWeatherInfo;

@interface UWWeatherAppDelegate : NSObject <NSApplicationDelegate> {
  NSMenu *noWeatherMenu;
  NSMenu *yesWeatherMenu;
  NSMenuItem *UWWeatherSubmenu;
  
  NSStatusItem *statusItem;
  UWWeatherInfo *weatherInfo;
  dispatch_queue_t stationInfoQueue;
  BOOL fetchingUpdate;
  SCNetworkReachabilityRef reachable;
  BOOL reachableScheduled;
}

@property (nonatomic, retain) IBOutlet NSMenu *noWeatherMenu;
@property (nonatomic, retain) IBOutlet NSMenu *yesWeatherMenu;
@property (nonatomic, retain) IBOutlet NSMenuItem *UWWeatherSubmenu;

- (IBAction)goToWeatherStationWebsite:(id)sender;
- (IBAction)goToApplicationWebsite:(id)sender;

@end
