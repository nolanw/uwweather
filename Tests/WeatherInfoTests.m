//
//  WeatherInfoTests.m
//  UWWeather
//
//  Created by Nolan Waite on 09-12-03.
//  Copyright 2009 Nolan Waite. All rights reserved.
//

#import <GHUnit/GHUnit.h>
#import "UWWeatherInfo.h"

@interface WeatherInfoTests : GHTestCase {}
@end

@implementation WeatherInfoTests

- (void)testLoadingSampleData
{
  NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"sample_data" withExtension:@"xml" subdirectory:nil] options:0 error:nil];
  NSAssert(doc, @"Couldn't open sample data.");
  UWWeatherInfo *info = [UWWeatherInfo weatherInfoWithXML:doc];
  
  GHAssertEqualObjects(info.observationDate, [NSDate dateWithString:@"2009-12-03 17:15:00 -0500"], @"Observation date.");
  GHAssertEquals([info.currentTemperature doubleValue], 2.6, @"Current temperature.");
  GHAssertEquals([info.feelsLikeTemperature doubleValue], -3.3, @"Feels like temperature.");
  GHAssertEquals([info.fifteenMinutesPrecipitation integerValue], 0, @"Fifteen minutes precipitation.");
  GHAssertEquals([info.oneHourPrecipitation integerValue], 0, @"One hour precipitation.");
  GHAssertEquals([info.twentyFourHoursPrecipitation integerValue], 15, @"Twenty-four hour precipitation.");
  GHAssertEquals([info.windSpeed doubleValue], 17.8, @"Wind speed");
  
  doc = [[NSXMLDocument alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"sample_data2" withExtension:@"xml" subdirectory:nil] options:0 error:nil];
  NSAssert(doc, @"Couldn't open sample data 2.");
  info = [UWWeatherInfo weatherInfoWithXML:doc];
  
  GHAssertEqualObjects(info.observationDate, [NSDate dateWithString:@"2009-12-05 21:00:00 -0500"], @"Observation date.");
  GHAssertEquals([info.currentTemperature doubleValue], -4.2, @"Current temperature.");
  GHAssertEquals([info.feelsLikeTemperature doubleValue], -5.3, @"Feels like temperature.");
  GHAssertEquals([info.fifteenMinutesPrecipitation integerValue], 0, @"Fifteen minutes precipitation.");
  GHAssertEquals([info.oneHourPrecipitation integerValue], 0, @"One hour precipitation.");
  GHAssertEquals([info.twentyFourHoursPrecipitation integerValue], 0, @"Twenty-four hour precipitation.");
  GHAssertEquals([info.windSpeed doubleValue], 2.2, @"Wind speed");
}

@end
