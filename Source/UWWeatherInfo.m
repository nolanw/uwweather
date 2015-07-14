// UWWeatherInfo.m – Public domain – http://nolanw.ca/uwweather/

#import "UWWeatherInfo.h"

// XPaths to useful info.
#define OBSERVATION_MONTH_PATH @".//observation_month_number"
#define OBSERVATION_DAY_PATH @".//observation_day[1]"
#define OBSERVATION_YEAR_PATH @".//observation_year[1]"
#define OBSERVATION_HOUR_PATH @".//observation_hour[1]"
#define OBSERVATION_MINUTE_PATH @".//observation_minute[1]"
#define TEMPERATURE_CURRENT @".//temperature_current_C[1]"
#define TEMPERATURE_HUMIDEX @".//humidex_C[1]"
#define TEMPERATURE_WINDCHILL @".//windchill_C[1]"
#define PRECIPITATION_FIFTEEN_MINUTES @".//precipitation_15minutes_mm[1]"
#define PRECIPITATION_ONE_HOUR @".//precipitation_1hr_mm[1]"
#define PRECIPITATION_TWENTY_FOUR_HOURS @".//precipitation_24hr_mm[1]"
#define WIND_SPEED @".//wind_speed_kph[1]"

// Time zone of UW Weather Station.
#define UW_TIME_ZONE @"America/Toronto"


@interface UWWeatherInfo ()
// Perform an XPath query on |xml| using each path in |paths|; return the 
// whitespace-trimmed contents of the first matching node.
- (NSArray *)_stringsForPaths:(NSArray *)paths inDocument:(NSXMLDocument *)xml;

// Given an XML document |xml| from the UW Weather Station, set the 
// |observationDate| instance variable by extracting info from |xml|.
- (void)_buildObservationDate:(NSXMLDocument *)xml;

// Given an XML document |xml| from the UW Weather Station, set the various 
// temperature, precipitation, and windchill instance variables by 
// extracting info from |xml|.
- (void)_pullTemperaturesAndPrecipitation:(NSXMLDocument *)xml;
@end


@implementation UWWeatherInfo {
    NSDate *observationDate;
    NSNumber *currentTemperature;
    NSNumber *feelsLikeTemperature;
    NSNumber *fifteenMinutesPrecipitation;
    NSNumber *oneHourPrecipitation;
    NSNumber *twentyFourHoursPrecipitation;
    NSNumber *windSpeed;
}

@synthesize observationDate;
@synthesize currentTemperature;
@synthesize feelsLikeTemperature;
@synthesize fifteenMinutesPrecipitation;
@synthesize oneHourPrecipitation;
@synthesize twentyFourHoursPrecipitation;
@synthesize windSpeed;

- (instancetype)initWithXML:(NSXMLDocument *)xml
{
  self = [super init];
  if (self)
  {
    [self _buildObservationDate:xml];
    [self _pullTemperaturesAndPrecipitation:xml];
  }
  return self;
}

+ (instancetype)weatherInfoWithXML:(NSXMLDocument *)xml
{
  return [[self alloc] initWithXML:xml];
}

- (NSArray *)_stringsForPaths:(NSArray *)paths inDocument:(NSXMLDocument *)xml
{
    NSMutableArray *strings = [NSMutableArray array];
    for (NSString *path in paths) {
        NSError *error = nil;
        NSArray *nodes = [xml nodesForXPath:path error:&error];
        NSAssert1([nodes count] > 0, @"No data for path %@", path);
        NSAssert2(error == nil, @"Error for path %@: %@", path, error);
        NSString *nodeString = [[nodes firstObject] stringValue];
        
        static NSRegularExpression *numberRegex;
        if (!numberRegex) {
            NSError *error;
            numberRegex = [NSRegularExpression regularExpressionWithPattern:@"(-?[0-9]+\\.?[0-9]*)" options:0 error:&error];
            NSAssert(numberRegex, @"error creating number regex: %@", error);
        }
        
        NSTextCheckingResult *result = [numberRegex firstMatchInString:nodeString options:0 range:NSMakeRange(0, nodeString.length)];
        NSRange range = [result rangeAtIndex:1];
        NSString *numberString;
        if (range.location != NSNotFound) {
            numberString = [nodeString substringWithRange:range];
        }
        if (numberString) {
            [strings addObject:numberString];
        } else {
            [strings addObject:nodeString];
        }
    }
    return strings;
}

- (void)_buildObservationDate:(NSXMLDocument *)xml
{
  NSArray *paths = @[OBSERVATION_MONTH_PATH, OBSERVATION_DAY_PATH, OBSERVATION_YEAR_PATH, OBSERVATION_HOUR_PATH, OBSERVATION_MINUTE_PATH];
  NSMutableArray *strings = [NSMutableArray arrayWithArray:[self _stringsForPaths:paths inDocument:xml]];
  NSTimeZone *eastern = [NSTimeZone timeZoneWithName:UW_TIME_ZONE];
  if ([eastern isDaylightSavingTime])
    [strings addObject:@"EDT"];
  else
    [strings addObject:@"EST"];
  
  NSString *dateString = [NSString stringWithFormat:@"%@/%@/%@ %@:%@ %@", [strings objectAtIndex:0], [strings objectAtIndex:1], [strings objectAtIndex:2], [strings objectAtIndex:3], [strings objectAtIndex:4], [strings objectAtIndex:5]];
  
  static NSDateFormatter *dateFormatter = nil;
  if (dateFormatter == nil)
  {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_CA"]];
    [dateFormatter setDateFormat:@"M/d/y H:mm z"];
  }
  
  observationDate = [dateFormatter dateFromString:dateString];
}

- (void)_pullTemperaturesAndPrecipitation:(NSXMLDocument *)xml
{
  NSArray *paths = @[TEMPERATURE_CURRENT, TEMPERATURE_HUMIDEX, TEMPERATURE_WINDCHILL, PRECIPITATION_FIFTEEN_MINUTES, PRECIPITATION_ONE_HOUR, PRECIPITATION_TWENTY_FOUR_HOURS, WIND_SPEED];
  NSArray *strings = [self _stringsForPaths:paths inDocument:xml];
  
  static NSNumberFormatter *numberFormatter = nil;
  if (numberFormatter == nil)
  {
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_CA"]];
    [numberFormatter setPositiveFormat:@"#0.#"];
    [numberFormatter setNegativeFormat:@"-#0.#"];
    [numberFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
  }
  
  currentTemperature = [numberFormatter numberFromString:[strings objectAtIndex:0]];
  feelsLikeTemperature = [numberFormatter numberFromString:[strings objectAtIndex:1]];
  if (feelsLikeTemperature == nil)
    feelsLikeTemperature = [numberFormatter numberFromString:[strings objectAtIndex:2]];
  if (feelsLikeTemperature == nil)
    feelsLikeTemperature = currentTemperature;
  fifteenMinutesPrecipitation = [numberFormatter numberFromString:[strings objectAtIndex:3]];
  if (fifteenMinutesPrecipitation == nil)
    fifteenMinutesPrecipitation = [NSNumber numberWithInteger:0];
  oneHourPrecipitation = [numberFormatter numberFromString:[strings objectAtIndex:4]];
  if (oneHourPrecipitation == nil)
    oneHourPrecipitation = [NSNumber numberWithInteger:0];
  twentyFourHoursPrecipitation = [numberFormatter numberFromString:[strings objectAtIndex:5]];
  if (twentyFourHoursPrecipitation == nil)
    twentyFourHoursPrecipitation = [NSNumber numberWithInteger:0];
  windSpeed = [numberFormatter numberFromString:[strings objectAtIndex:6]];
  if (windSpeed == nil)
    windSpeed = [NSNumber numberWithInteger:0];
}

@end
