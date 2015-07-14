//
//  UWWeatherInfo.h
//  UWWeather
//
//  Created by Nolan Waite on 09-12-03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


// Parses XML from the UW Weather Station into more readable values.
@interface UWWeatherInfo : NSObject

@property (readonly) NSDate *observationDate;

// In degrees Celsius.
@property (readonly) NSNumber *currentTemperature;

// Whichever of humidex or windchill is not nil, unless both are.
@property (readonly) NSNumber *feelsLikeTemperature;

// In millimetres.
@property (readonly) NSNumber *fifteenMinutesPrecipitation;

// In millimetres.
@property (readonly) NSNumber *oneHourPrecipitation;

// In millimetres.
@property (readonly) NSNumber *twentyFourHoursPrecipitation;

// In kilometres per hour.
@property (readonly) NSNumber *windSpeed;

// Return autoreleased instance of self using designated initializer.
+ (instancetype)weatherInfoWithXML:(NSXMLDocument *)xml;

- (instancetype)initWithXML:(NSXMLDocument *)xml NS_DESIGNATED_INITIALIZER;

@end
