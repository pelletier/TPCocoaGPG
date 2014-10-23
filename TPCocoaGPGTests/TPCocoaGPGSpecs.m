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
  
  beforeEach(^{
    // Create a temporary home directory for each test
    _tmpHome = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]
                                     isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:_tmpHome withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Create a TPCocoaGPG instance;
    gpg = [[TPCocoaGPG alloc] initGpgPath:@"/usr/local/bin/gpg" andHome:[_tmpHome path]];
  });
  
  it(@"can be created", ^{
    expect(gpg).toNot.beNil();
  });
  
  it(@"can import keys and list them", ^{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForResource:@"example" ofType:@"pub"];
    NSError* err;
    NSString* pubkeyContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    NSString* privkeyContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    expect(pubkeyContent).toNot.beNil();
    expect(privkeyContent).toNot.beNil();
    
    [gpg importIntoKeyring:pubkeyContent];
    
    NSArray* pubKeys = [gpg listPublicKeys];
    NSArray* privKeys = [gpg listPrivateKeys];
    
    expect(pubKeys.count).to.equal(1);
    expect(privKeys.count).to.equal(0);
  });
  
  afterEach(^{
    // Remove the temporary directory
    [[NSFileManager defaultManager] removeItemAtPath:[_tmpHome absoluteString] error:nil];
  });
});

SpecEnd