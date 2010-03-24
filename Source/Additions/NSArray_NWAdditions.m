//
//  NSArray_NWAdditions.m
//  Schoolstuff
//
//  Created by Nolan Waite on 09-09-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSArray_NWAdditions.h"


@implementation NSArray (NWAdditions)
- (id)firstObject
{
  if ([self count] < 1) {
    return nil;
  }
  return [self objectAtIndex:0];
}

- (NSArray *)filteredArrayWithBlock:(BOOL(^)(id element))block
{
  NSMutableArray *filteredArray = [NSMutableArray array];
  for (id element in self) {
    if (block(element)) {
      [filteredArray addObject:element];
    }
  }
  return filteredArray;
}
@end
