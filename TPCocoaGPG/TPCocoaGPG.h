//
//  TPCocoaGPG.h
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>
#import "TPGPGKey.h"

/**
 Wrapper around the gpg binary to perform simple cryptography operations.
 */
@interface TPCocoaGPG : NSObject {
 @private
  NSString* _home;
  NSString* _gpgPath;
}

/**
 Initializes the wrapper and set up gpg to store files (e.g. keys, rings, etc.) in `home`.
 
 @param gpgPath The absolute path to the gpg binary.
 @param home The absolute path for the local data storage.
 @return The new instance
 */
- (id)initGpgPath:(NSString*)gpgPath andHome:(NSString*)home;


/// ------------------------------------------------------------------------------------------------
/// @name Managing keys
/// ------------------------------------------------------------------------------------------------


/**
 Import a key into the keyring.
 
 @param key String representation of the key to import.
 */
- (void)importIntoKeyring:(NSString*)key;

/**
 Lists the currently stored public keys.
 
 @return An array of `TPGPGKey`.
 */
- (NSArray*)listPublicKeys;

/**
 Lists the currently stored private keys.
 
 @return An array of `TPGPGKey`.
 */
- (NSArray*)listSecretKeys;

/**
 Grabs the public key associated with a given fingerprint.
 
 @param fingerprint The fingerprint to look up.
 @return An instance of `TPGPGKey` representing the key, or `nil` if it is not on the keyring.
 */
- (TPGPGKey*)getPublicKeyWithFingerprint:(NSString*)fingerprint;

/**
 Grabs the private key associated with a given fingerprint.
 
 @param fingerprint The fingerprint to look up.
 @return An instance of `TPGPGKey` representing the key, or `nil` if it is not on the keyring.
 */
- (TPGPGKey*)getSecretKeyWithFingerprint:(NSString*)fingerprint;

/**
 Checks if a given passphrase unlocks a given key.
 
 @param passphrase Passphrase to try.
 @param key Key to try to unlock.
 @return YES if the passphrase is indeed correct for the key.
 */
- (BOOL)checkIfPassphrase:(NSString*)passphrase unlocksKey:(TPGPGKey*)key;

/**
 Generate a public / private keys pair protected by a passphrase.
 
 @param length Length of the key in bits (1024 or 2048 only)
 @param email Email of the key owner
 @param name Name of the key owner
 @param comment Comment attached to the key
 @param passphrase Passphrase to protect the key.
 @return Returns the fingerprint of the generated key (or nil if it failed).
*/
- (NSString*)generateKeysWithLength:(int)length
                              email:(NSString*)email
                               name:(NSString*)name
                            comment:(NSString*)comment
                      andPassphrase:(NSString*)passphrase;

/**
 Export the armored, ascii representation of a given key.

 @param key Key to export
 @return The textual output or nil if it failed to export.
*/
- (NSData*)exportKey:(TPGPGKey*)key;

/// ------------------------------------------------------------------------------------------------
/// @name Encrypt and decrypt data
/// ------------------------------------------------------------------------------------------------

/**
 Encrypt some data with an optional passphrase.
 
 @param data Data to encrypt.
 @param key Key to use to perform the encryption.
 @param passphrase Optional passphrase to unlock the key.
 @return The encrypted, armored data. Can be directly converted to an NSString if needed.
 */
- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase;

/**
 Encrypt some data without passphrase.
 
 @see -encryptData:withKey:andPassphrase
 */
- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key;

/**
 Decrypt some data with an optional passphrase.
 
 @param data Data to decrypt.
 @param key Key to use to perform the decryption.
 @param passphrase Optional passphrase to unlock the key.
 @return The decrypted data.
 */
- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase;

/**
 Decrypt some data without passphrase.
 
 @see -edecyrptData:withKey:andPassphrase
 */
- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key;

@end
