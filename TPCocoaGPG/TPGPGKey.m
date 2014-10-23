//
//  TPGPGKey.m
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import "TPGPGKey.h"

NSString *const kTPCocoaGPGTypeKey = @"type";
NSString *const kTPCocoaGPGTrustKey = @"trust";
NSString *const kTPCocoaGPGLengthKey = @"length";
NSString *const kTPCocoaGPGAlgoKey = @"algo";
NSString *const kTPCocoaGPGKeyIdKey = @"keyid";
NSString *const kTPCocoaGPGDateKey = @"date";

@implementation TPGPGKey

- (id)init {
  if ((self = [super init])) {
    _data = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (NSString*)getValue:(NSString*)key {
  return [_data objectForKey:key];
}

- (void)setValue:(NSString*)value forKey:(NSString*)key {
  [_data setObject:value forKey:key];
}

- (NSString*)keyId {
  return [self getValue:kTPCocoaGPGKeyIdKey];
}

@end
