//
//  NSString_NWAdditions.m
//  UWWeather
//
//  Created by Nolan Waite on 09-12-03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSString_NWAdditions.h"


@implementation NSString (NWAdditions)

- (NSString *)trimWhitespace
{
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
