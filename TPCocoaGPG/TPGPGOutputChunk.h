//
//  TPGPGOutputChunk.h
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>

/**
 Internal representation of GPG's parsed standard error.
 */
@interface TPGPGOutputChunk : NSObject {
  NSString* _key;
  NSString* _text;
}

/**
 Allocate and initialize a new chunk.
 
 @param key Output key
 @param text Associated text
 @return The new chunk
*/
+ (TPGPGOutputChunk*)makeWithKey:(NSString*)key andText:(NSString*)text;

@property (nonatomic, assign) NSString* key;
@property (nonatomic, assign) NSString* text;

@end
