//
//  UWWeatherAppDelegate.m
//  UWWeather
//
//  Created by Nolan Waite on 09-12-03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UWWeatherAppDelegate.h"
#import "UWWeatherInfo.h"

#import "NWLoginItems.h"


#define SHOW_FEELS_LIKE_PREFERENCE @"ShowFeelsLikeInMenuBar"
#define START_AT_LOGIN_PREFERENCE @"StartAtLogin"
#define WEATHER_STATION_URL @"http://weather.uwaterloo.ca/"
#define APPLICATION_URL @"http://nolanw.ca/uwweather/"
#define WEATHER_XML_URL @"http://weather.uwaterloo.ca/waterloo_weather_station_data.xml"
#define WEATHER_XML_HOST "weather.uwaterloo.ca" // C string
#define NO_WEATHER_STATUS_ITEM_TITLE @"UW"
#define UPDATE_INTERVAL_NORMAL (60.0 * 15.0)
#define UPDATE_INTERVAL_LAST_FAILED (60.0 * 5.0)
#define UPDATE_INTERVAL_WAKE_FROM_SLEEP (60.0 * 1.5)
#define UNKNOWN_WEATHER_FAILED_INTERVAL (60.0 * 60.0 * 3.0)
#define MENU_ITEM_TAG_DATE 10
#define MENU_ITEM_TAG_CURRENTLY 11
#define MENU_ITEM_TAG_PRECIPITATION_FIFTEEN_MINUTES 12
#define MENU_ITEM_TAG_PRECIPITATION_ONE_HOUR 13
#define MENU_ITEM_TAG_PRECIPITATION_TWENTY_FOUR_HOURS 14
#define SUBMENU_ITEM_TAG_START_ON_LOGIN 5


@interface UWWeatherAppDelegate ()

@property (retain) UWWeatherInfo *weatherInfo;

// Asynchronously retrieves the latest weather information from the station.
- (void)_fetchUpdate;

// Update values in the weather menu using |newInfo| and preferences.
- (void)_updateWeatherMenu;

// Set a timer to update in |time| seconds.
- (void)_updateIn:(NSTimeInterval)time;

@end


@implementation UWWeatherAppDelegate

@synthesize weatherInfo;
@synthesize noWeatherMenu;
@synthesize yesWeatherMenu;
@synthesize UWWeatherSubmenu;

+ (void)initialize
{
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:@{SHOW_FEELS_LIKE_PREFERENCE: @NO, START_AT_LOGIN_PREFERENCE: @NO}];
}

- (void)dealloc
{
    CFRelease(reachable);
}

- (void)awakeFromNib
{
    for (NSMenu *menu in @[noWeatherMenu, yesWeatherMenu]) {
        [menu addItem:[NSMenuItem separatorItem]];
        NSMenuItem *submenu = [UWWeatherSubmenu copy];
        [[[submenu submenu] itemWithTag:SUBMENU_ITEM_TAG_START_ON_LOGIN] bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", START_AT_LOGIN_PREFERENCE] options:nil];
        [menu addItem:submenu];
    }
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        [(__bridge UWWeatherAppDelegate *)info _fetchUpdate];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setTitle:NO_WEATHER_STATUS_ITEM_TITLE];
    [statusItem setMenu:noWeatherMenu];
    [statusItem setHighlightMode:YES];
    stationInfoQueue = dispatch_queue_create("com.nwaite.UWWeather.StationInfoQueue", NULL);
    
    [self addObserver:self forKeyPath:@"weatherInfo" options:0 context:KVOContext];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:[NSString stringWithFormat:@"values.%@", SHOW_FEELS_LIKE_PREFERENCE]
                                                                 options:0
                                                                 context:KVOContext];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:[NSString stringWithFormat:@"values.%@", START_AT_LOGIN_PREFERENCE]
                                                                 options:0
                                                                 context:KVOContext];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(awokeFromSleep:) name:NSWorkspaceDidWakeNotification object:nil];
    
    reachable = SCNetworkReachabilityCreateWithName(NULL, WEATHER_XML_HOST);
    SCNetworkReachabilityContext context;
    context.version = 0;
    context.info = (__bridge void *)self;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    SCNetworkReachabilitySetCallback(reachable, ReachabilityCallback, &context);
    
    [self _fetchUpdate];
}

static void *KVOContext = &KVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != KVOContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    if ([keyPath isEqualToString:@"weatherInfo"]) {
        [self updateWithInfo:self.weatherInfo];
    } else if ([keyPath isEqualToString:[NSString stringWithFormat:@"values.%@", SHOW_FEELS_LIKE_PREFERENCE]]) {
         [self _updateWeatherMenu];
    } else if ([keyPath isEqualToString:[NSString stringWithFormat:@"values.%@", START_AT_LOGIN_PREFERENCE]]) {
        if ([[[object values] valueForKey:START_AT_LOGIN_PREFERENCE] boolValue]) {
            [NWLoginItems addBundleToSessionLoginItems:nil];
        } else {
            [NWLoginItems removeBundleFromSessionLoginItems:nil];
        }
    } else {
        NSAssert(NO, @"unexpected change observed at key path: %@", keyPath);
    }
}

- (void)updateWithInfo:(UWWeatherInfo *)newInfo {
    if (newInfo == nil)
    {
        [statusItem setTitle:NO_WEATHER_STATUS_ITEM_TITLE];
        [statusItem setMenu:noWeatherMenu];
        return;
    }
    [self _updateWeatherMenu];
    [statusItem setMenu:yesWeatherMenu];
}

- (void)awokeFromSleep:(NSNotification *)note
{
    [self _updateIn:UPDATE_INTERVAL_WAKE_FROM_SLEEP];
}

- (IBAction)goToWeatherStationWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:WEATHER_STATION_URL]];
}

- (IBAction)goToApplicationWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:APPLICATION_URL]];
}

- (void)updateFailed
{
    if (!reachableScheduled)
    {
        reachableScheduled = YES;
        SCNetworkReachabilityScheduleWithRunLoop(reachable, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    }
    if (weatherInfo != nil)
    {
        if ([[NSDate date] timeIntervalSinceDate:weatherInfo.observationDate] > UNKNOWN_WEATHER_FAILED_INTERVAL)
        {
            [statusItem setTitle:NO_WEATHER_STATUS_ITEM_TITLE];
            [statusItem setMenu:noWeatherMenu];
        }
    }
    [self _updateIn:UPDATE_INTERVAL_LAST_FAILED];
}

- (void)updateTimerRing:(NSTimer *)timer
{
    [self _fetchUpdate];
}

- (void)_fetchUpdate
{
    if (fetchingUpdate)
        return;
    
    fetchingUpdate = YES;
    
    UWWeatherAppDelegate *appDelegate = self;
    dispatch_async(stationInfoQueue, ^{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:WEATHER_XML_URL]];
        NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
        dispatch_sync(dispatch_get_main_queue(), ^{
            fetchingUpdate = NO;
            if (reachableScheduled)
            {
                SCNetworkReachabilityUnscheduleFromRunLoop(reachable, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
                reachableScheduled = NO;
            }
            
            if (data == nil)
            {
                [appDelegate updateFailed];
                return;
            }
            NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:data options:0 error:nil];
            if (xml == nil)
            {
                [appDelegate updateFailed];
                return;
            }
            [appDelegate setWeatherInfo:[UWWeatherInfo weatherInfoWithXML:xml]];
            [appDelegate _updateIn:UPDATE_INTERVAL_NORMAL];
        });
    });
}

static double FixNegativeZero(double a)
{
    if (a >= -0.5 && a < 0.5)
        return 0.0;
    return a;
}

- (void)_updateWeatherMenu
{
    BOOL showFeelsLike = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:SHOW_FEELS_LIKE_PREFERENCE] boolValue];
    if (showFeelsLike)
        [statusItem setTitle:[NSString stringWithFormat:@"%.0fº", FixNegativeZero([weatherInfo.feelsLikeTemperature doubleValue])]];
    else
        [statusItem setTitle:[NSString stringWithFormat:@"%.0fº", FixNegativeZero([weatherInfo.currentTemperature doubleValue])]];
    NSMenuItem *item = [yesWeatherMenu itemWithTag:MENU_ITEM_TAG_DATE];
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    [item setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"As of", @"Text before the date in the first menu item"), [dateFormatter stringFromDate:weatherInfo.observationDate]]];
    item = [yesWeatherMenu itemWithTag:MENU_ITEM_TAG_CURRENTLY];
    if (showFeelsLike)
        [item setTitle:[NSString stringWithFormat:@"%@: %.1fºC", NSLocalizedString(@"Actual Temperature", @"Text before temperature in second menu item when showing actual temperature"), [weatherInfo.currentTemperature doubleValue]]];
    else
        [item setTitle:[NSString stringWithFormat:@"%@: %.1fºC", NSLocalizedString(@"Feels Like", @"Text before temperature in second menu item when showing windchill/humidex"), [weatherInfo.feelsLikeTemperature doubleValue]]];
    item = [yesWeatherMenu itemWithTag:MENU_ITEM_TAG_PRECIPITATION_FIFTEEN_MINUTES];
    [item setTitle:[NSString stringWithFormat:@"…%@: %ldmm", NSLocalizedString(@"last 15 minutes", @"Text before measurement in menu item for precipitation in the last fifteen minutes"), (long)[weatherInfo.fifteenMinutesPrecipitation integerValue]]];
    item = [yesWeatherMenu itemWithTag:MENU_ITEM_TAG_PRECIPITATION_ONE_HOUR];
    [item setTitle:[NSString stringWithFormat:@"…%@: %ldmm", NSLocalizedString(@"last hour", @"Text before measurement in menu item for precipitation in the last hour"), (long)[weatherInfo.oneHourPrecipitation integerValue]]];
    item = [yesWeatherMenu itemWithTag:MENU_ITEM_TAG_PRECIPITATION_TWENTY_FOUR_HOURS];
    [item setTitle:[NSString stringWithFormat:@"…%@: %ldmm", NSLocalizedString(@"last 24 hours", @"Text before measurement in menu item for precipitation in the last twenty-four hours"), (long)[weatherInfo.twentyFourHoursPrecipitation integerValue]]];
}

- (void)_updateIn:(NSTimeInterval)time
{
    [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(updateTimerRing:) userInfo:nil repeats:NO];
}

@end
