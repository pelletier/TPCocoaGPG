//
//  TPGPGKey.h
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>

extern NSString *const kTPCocoaGPGTypeKey;
extern NSString *const kTPCocoaGPGTrustKey;
extern NSString *const kTPCocoaGPGLengthKey;
extern NSString *const kTPCocoaGPGAlgoKey;
extern NSString *const kTPCocoaGPGKeyIdKey;
extern NSString *const kTPCocoaGPGDateKey;

/**
 Encapsulate a key (public or private).
 
 This class is basically a wrapper around a dictionary. You should not need to access the internals
 directly.
 */
@interface TPGPGKey : NSObject {
 @private
  NSMutableDictionary* _data;
}

/**
 Initializes the object.
 */
- (id)init;

/**
 Retrieves a value stored for a key.
 
 @param key Key to lookup.
 @return The associated value (possibly nil).
 */
- (NSString*)getValue:(NSString*)key;

/**
 Store a value associated with a key.
 
 @param value Value to store.
 @param key Key to store it at.
 */
- (void)setValue:(NSString*)value forKey:(NSString*)key;

/**
 Shortcut to grab the key id.
 
 @return The key id (or fingerprint).
 */
- (NSString*)keyId;

@end
