//
//  NSArray_NWAdditions.h
//  Schoolstuff
//
//  Created by Nolan Waite on 09-09-26.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (NWAdditions)

// Returns the object at index 0, or nil if empty.
- (id)firstObject;

// Returns an autoreleased array of all elements in this array that caused 
// |block| to return YES.
- (NSArray *)filteredArrayWithBlock:(BOOL(^)(id element))block;

@end
