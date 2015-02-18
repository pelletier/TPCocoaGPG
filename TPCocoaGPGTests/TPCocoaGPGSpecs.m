//
//  TPCocoaGPGSpecs.m
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import <Foundation/Foundation.h>
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "TPCocoaGPG.h"

SpecBegin(TPCocoaGPG)

describe(@"TPCocoaGPG", ^{
  __block TPCocoaGPG* gpg;
  __block NSURL* _tmpHome;
  __block NSString* pubkeyContent;
  __block NSString* privkeyContent;
  
  beforeEach(^{
    // Create a temporary home directory for each test
    _tmpHome = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]
                                     isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:_tmpHome withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Create a TPCocoaGPG instance;
    gpg = [[TPCocoaGPG alloc] initGpgPath:@"/usr/local/bin/gpg" andHome:[_tmpHome path]];
    
    // Prepare some keys
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"example" ofType:@"pub"];
    NSError* err;
    pubkeyContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    path = [bundle pathForResource:@"example" ofType:@"sec"];
    privkeyContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    expect(pubkeyContent).toNot.beNil();
    expect(privkeyContent).toNot.beNil();
  });
  
  it(@"can be created", ^{
    expect(gpg).toNot.beNil();
  });
  
  it(@"can import keys and list them", ^{
    [gpg importIntoKeyring:pubkeyContent];
    
    NSArray* pubKeys = [gpg listPublicKeys];
    NSArray* privKeys = [gpg listSecretKeys];
    
    expect(pubKeys.count).to.equal(1);
    expect(privKeys.count).to.equal(0);
    
    TPGPGKey* key = [pubKeys firstObject];
    expect([key getValue:kTPCocoaGPGKeyIdKey]).to.equal(@"F2479DE6CFB6B695");
    
    [gpg importIntoKeyring:privkeyContent];
    
    pubKeys = [gpg listPublicKeys];
    privKeys = [gpg listSecretKeys];
    
    expect(pubKeys.count).to.equal(1);
    expect(privKeys.count).to.equal(1);
    
    key = [privKeys firstObject];
    expect([key getValue:kTPCocoaGPGKeyIdKey]).to.equal(@"F2479DE6CFB6B695");
  });
  
  it(@"can import keys and retrieve it by fingerprint", ^{
    NSString* fingerprint = [gpg importIntoKeyring:pubkeyContent];
    TPGPGKey* key = [gpg getPublicKeyWithFingerprint:fingerprint];
    expect(key).toNot.beNil();
    expect([key getValue:kTPCocoaGPGKeyIdKey]).to.equal(fingerprint);
  });
  
  it(@"can retrieve a key by fingerprint", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    
    TPGPGKey* key = [gpg getPublicKeyWithFingerprint:@"F2479DE6CFB6B695"];
    expect(key).toNot.beNil();
    expect([key getValue:kTPCocoaGPGKeyIdKey]).to.equal(@"F2479DE6CFB6B695");

    key = [gpg getPublicKeyWithFingerprint:@"BAD"];
    expect(key).beNil();
    
    key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    expect(key).toNot.beNil();
    expect([key getValue:kTPCocoaGPGKeyIdKey]).to.equal(@"F2479DE6CFB6B695");
    
    key = [gpg getSecretKeyWithFingerprint:@"BAD"];
    expect(key).beNil();
  });
  
  it(@"can check passphrases", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    expect([gpg checkIfPassphrase:@"HELLOWORLD" unlocksKey:key]).to.equal(NO);
    expect([gpg checkIfPassphrase:@"MyActualPasskey" unlocksKey:key]).to.equal(YES);
  });
  
  it(@"can decrypt data", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"foo" ofType:@"crypt"];
    NSData* secretFile = [NSData dataWithContentsOfFile:path];
    NSData* decryptedData = [gpg decryptData:secretFile withKey:key andPassphrase:@"MyActualPasskey"];
    NSString* plain = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    expect([plain isEqualToString:@"My great message to secure"]).to.equal(YES);
  });
  
  it(@"can encrypt data", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    NSString* message = @"My great message to secure";
    NSData* someData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData* encryptedData = [gpg encryptData:someData withKey:key andPassphrase:@"MyActualPasskey"];
    expect(encryptedData).notTo.beNil;
    NSData* decryptedData = [gpg decryptData:encryptedData withKey:key andPassphrase:@"MyActualPasskey"];
    expect([decryptedData isEqualToData:someData]).to.equal(YES);
  });
  
  it(@"can encrypt and decrypt binary data", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"logo" ofType:@"png"];
    NSData* secretFile = [NSData dataWithContentsOfFile:path];
    NSData* encryptedData = [gpg encryptData:secretFile withKey:key andPassphrase:@"MyActualPasskey"];
    expect(encryptedData).notTo.beNil;
    NSData* decryptedData = [gpg decryptData:encryptedData withKey:key andPassphrase:@"MyActualPasskey"];
    expect([decryptedData isEqualToData:secretFile]).to.equal(YES);
  });
  
  it(@"can encrypt large binary data", ^{
    [gpg importIntoKeyring:pubkeyContent];
    [gpg importIntoKeyring:privkeyContent];
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:@"F2479DE6CFB6B695"];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"LargeEverest" ofType:@"jpg"];
    NSData* secretFile = [NSData dataWithContentsOfFile:path];
    NSData* encryptedData = [gpg encryptData:secretFile withKey:key andPassphrase:@"MyActualPasskey"];
    expect(encryptedData).notTo.beNil;
    NSData* decryptedData = [gpg decryptData:encryptedData withKey:key andPassphrase:@"MyActualPasskey"];
    expect([decryptedData isEqualToData:secretFile]).to.equal(YES);
  });
  
  it(@"can create keys", ^{
    int length = 2048;
    NSString* fingerprint = [gpg generateKeysWithLength:length email:@"test@example.com" name:@"example" comment:@"example" andPassphrase:@"qweqwe"];
    expect(fingerprint).notTo.beNil;
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:fingerprint];
    expect(key).notTo.beNil;
    expect([key getValue:kTPCocoaGPGLengthKey]).to.equal([NSString stringWithFormat:@"%d", length]);
  });
  
  it(@"can export a private key", ^{
    NSString* fingerprint = [gpg generateKeysWithLength:2048 email:@"test@example.com" name:@"example" comment:@"example" andPassphrase:@"qweqwe"];
    expect(fingerprint).notTo.beNil;
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:fingerprint];
    expect(key).notTo.beNil;
    NSData* data = [gpg exportKey:key];
    expect(data).notTo.beNil;
    NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    expect(string.length).notTo.beLessThanOrEqualTo(0);
    expect([string hasPrefix:@"-----BEGIN PGP PRIVATE KEY BLOCK-----"]).to.equal(YES);
    expect([string hasSuffix:@"-----END PGP PRIVATE KEY BLOCK-----"]).to.equal(YES);
  });
  
  it(@"can export a public key", ^{
    NSString* fingerprint = [gpg generateKeysWithLength:2048 email:@"test@example.com" name:@"example" comment:@"example" andPassphrase:@"qweqwe"];
    expect(fingerprint).notTo.beNil;
    TPGPGKey* key = [gpg getPublicKeyWithFingerprint:fingerprint];
    expect(key).notTo.beNil;
    NSData* data = [gpg exportKey:key];
    expect(data).notTo.beNil;
    NSString* string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    expect(string.length).notTo.beLessThanOrEqualTo(0);
    expect([string hasPrefix:@"-----BEGIN PGP PUBLIC KEY BLOCK-----"]).to.equal(YES);
    expect([string hasSuffix:@"-----END PGP PUBLIC KEY BLOCK-----"]).to.equal(YES);
  });
  
  it(@"can change the passphrase of a key", ^{
    NSString* fingerprint = [gpg generateKeysWithLength:2048 email:@"test@example.com" name:@"example" comment:@"example" andPassphrase:@"oldold"];
    expect(fingerprint).notTo.beNil;
    TPGPGKey* key = [gpg getSecretKeyWithFingerprint:fingerprint];
    expect(key).notTo.beNil;
    expect([gpg checkIfPassphrase:@"oldold" unlocksKey:key]).to.equal(YES);
    expect([gpg checkIfPassphrase:@"newnew" unlocksKey:key]).to.equal(NO);
    expect([gpg changePassphraseFor:key withOldPassphrase:@"badbad" toNewPassphrase:@"foo"]).to.equal(NO);
    expect([gpg changePassphraseFor:key withOldPassphrase:@"oldold" toNewPassphrase:@"newnew"]).to.equal(YES);
    expect([gpg checkIfPassphrase:@"oldold" unlocksKey:key]).to.equal(NO);
    expect([gpg checkIfPassphrase:@"newnew" unlocksKey:key]).to.equal(YES);
  });
  
  afterEach(^{
    // Remove the temporary directory
    [[NSFileManager defaultManager] removeItemAtPath:[_tmpHome absoluteString] error:nil];
  });
});

SpecEnd