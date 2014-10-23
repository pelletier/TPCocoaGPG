//
//  TPCocoaGPG.h
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>
#import "TPGPGKey.h"

// Wrapper around the gpg binary to perform simple cryptography operations.
@interface TPCocoaGPG : NSObject {
 @private
  NSString* _home;
  NSString* _gpgPath;
}

// Initializes the wrapper and set up gpg to store files (e.g. keys, rings, etc.) in |home|.
// |gpgPath| is the absolute path to the gpg binary to wrap.
- (id)initGpgPath:(NSString*)gpgPath andHome:(NSString*)home;

// Returns an array of |TPGPGKey|s.
- (NSArray*)listPublicKeys;
- (NSArray*)listPrivateKeys;

// Returns the |TPGPGKey| associated to the given |fingerprint|.
// Returns NULL if the key does not exist.
- (TPGPGKey*)getKeyWithFingerprint:(NSString*)fingerprint;

// Encrypts some |data| with the given |key|.
- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key;

// Decrypts some |data| with the given |key| and uses |passphrase| to unlock the key (if needed).
- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase;
- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key;

// Checks if |passphrase| unlocks the given |key|.
// Internally, this method uses signing.
- (BOOL)checkIfPassphrase:(NSString*)passphrase unlocksKey:(TPGPGKey*)key;

// Import |key| into keyring.
- (void)importIntoKeyring:(NSString*)key;

@end
