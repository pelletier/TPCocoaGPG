//
//  TPGPGOutputChunk.h
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>

@interface TPGPGOutputChunk : NSObject {
  NSString* _key;
  NSString* _text;
}

+ (TPGPGOutputChunk*)makeWithKey:(NSString*)key andText:(NSString*)text;

@property (nonatomic, assign) NSString* key;
@property (nonatomic, assign) NSString* text;

@end
