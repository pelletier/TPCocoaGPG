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

// Encapsulate a key (public or private).
@interface TPGPGKey : NSMutableDictionary {

}

@end
