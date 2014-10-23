//
//  TPGPGOutputChunk.m
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import "TPGPGOutputChunk.h"

@implementation TPGPGOutputChunk

@synthesize key;
@synthesize text;

+ (TPGPGOutputChunk*)makeWithKey:(NSString*)key andText:(NSString*)text {
  TPGPGOutputChunk* chunk = [[TPGPGOutputChunk alloc] init];
  chunk.key = key;
  chunk.text = text;
  return chunk;
}

@end
