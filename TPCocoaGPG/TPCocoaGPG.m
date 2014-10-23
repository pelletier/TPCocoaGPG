//
//  TPCocoaGPG.m
//  TPCocoaGPG
//
//  Created by Thomas Pelletier on 10/23/14.
//  Copyright (c) 2014 Thomas Pelletier. See LICENSE.
//

#import "TPCocoaGPG.h"
#import "TPGPGOutputChunk.h"

@implementation TPCocoaGPG

#pragma mark - Public interface

#pragma mark Initialization

- (id)initGpgPath:(NSString*)gpgPath andHome:(NSString*)home {
  if ((self = [super init])) {
    _home = home;
    _gpgPath = gpgPath;
  }
  
  return self;
}

#pragma mark Keys management

- (NSArray*)listPublicKeys {
  return [self listKeysForSecretKeys:NO andFilter:nil];
}

- (NSArray*)listSecretKeys {
  return [self listKeysForSecretKeys:YES andFilter:nil];
}

- (TPGPGKey*)getSecretKeyWithFingerprint:(NSString*)fingerprint {
  NSArray* keys = [self listKeysForSecretKeys:YES andFilter:fingerprint];
  if (keys.count == 0) {
    return nil;
  }
  return keys.firstObject;
}

- (TPGPGKey*)getPublicKeyWithFingerprint:(NSString*)fingerprint {
  NSArray* keys = [self listKeysForSecretKeys:NO andFilter:fingerprint];
  if (keys.count == 0) {
    return nil;
  }
  return keys.firstObject;
}

- (NSArray*)listKeysForSecretKeys:(BOOL)secret andFilter:(NSString*)fingerprint {
  NSMutableArray* stdoutLines;
  NSError* error;
  
  // Prepare the command to run
  NSMutableArray* args = [NSMutableArray arrayWithArray:@[@"--fixed-list-mode", @"--fingerprint", @"--with-colons"]];
  if (secret) {
    [args addObject:@"--list-secret-keys"];
  } else {
    [args addObject:@"--list-keys"];
  }
  if (fingerprint != nil) {
    [args addObject:fingerprint];
  }
  [self execCommand:args withInput:nil stderrChunks:nil stdoutLines:&stdoutLines andError:&error];
  
  // Fields in order of appearence for each key line in stdout.
  NSArray* parsedFields = @[kTPCocoaGPGTypeKey, kTPCocoaGPGTrustKey, kTPCocoaGPGLengthKey, kTPCocoaGPGAlgoKey, kTPCocoaGPGKeyIdKey, kTPCocoaGPGDateKey];
  NSMutableArray* keys = [[NSMutableArray alloc] init];
  
  // Every line represents something
  for (NSString* line in stdoutLines) {
    // A key has at least 6 components
    NSArray* fields = [line componentsSeparatedByString:@":"];
    if (fields.count < parsedFields.count) {
      continue;
    }
    // Make sure it's a key
    NSString* type = (NSString*)[fields firstObject];
    if (![type isEqualToString:@"sec"] && ![type isEqualToString:@"pub"]) {
      continue;
    }
    
    // Generate the new key object
    TPGPGKey* key = [[TPGPGKey alloc] init];
    for (unsigned i = 0; i < parsedFields.count; ++i) {
      [key setValue:[fields objectAtIndex:i] forKey:[parsedFields objectAtIndex:i]];
    }
    [keys addObject:key];
  }
  
  return keys;
}

- (void)importIntoKeyring:(NSString*)key {
  [self execCommand:@[@"--import"] withInput:key stderrChunks:nil stdoutLines:nil andError:nil];
}

- (BOOL)checkIfPassphrase:(NSString*)passphrase unlocksKey:(TPGPGKey*)key {
  if (key == nil) {
    return NO;
  }
  NSArray* args = @[@"--batch",
                    @"--passphrase-fd", @"0",
                    @"--no-use-agent",
                    @"--local-user", [key getValue:kTPCocoaGPGKeyIdKey],
                    @"-sa"];
  NSString* input = [NSString stringWithFormat:@"%@\nThis is a random string\n", passphrase];
  NSMutableArray* stderrChunks;
  [self execCommand:args withInput:input stderrChunks:&stderrChunks stdoutLines:nil andError:nil];
  for (TPGPGOutputChunk* chunk in stderrChunks) {
    if ([chunk.key isEqualToString:@"GOOD_PASSPHRASE"]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark Encryption

- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key {
  return nil;
}

- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase {
  return nil;
}

- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key {
  return nil;
}

#pragma mark - Private helpers

- (void)execCommand:(NSArray*)commands
          withInput:(NSString*)input
       stderrChunks:(NSMutableArray**)stderrChunks
        stdoutLines:(NSMutableArray**)stdoutLines
           andError:(NSError**)error {
  NSMutableArray* args = [NSMutableArray arrayWithArray:@[@"--verbose", @"--status-fd", @"2", @"--no-tty", @"--homedir", _home]];
  [args addObjectsFromArray:commands];
  
  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:_gpgPath];
  [task setArguments:args];

  // Prepare stdin if necessary.
  NSPipe* stdinPipe;
  NSFileHandle* stdinHandle;
  if (input != nil && input.length > 0) {
    stdinPipe = [NSPipe pipe];
    stdinHandle = [stdinPipe fileHandleForWriting];
    [task setStandardInput:stdinPipe];
  }
  
  // Prepare stdout
  NSPipe* stdoutPipe;
  if (stdoutLines != nil) {
    stdoutPipe = [NSPipe pipe];
    [task setStandardOutput:stdoutPipe];
  }
  
  // Prepare stderr
  NSPipe* stderrPipe;
  if (stderrChunks != nil) {
    stderrPipe = [NSPipe pipe];
    [task setStandardError:stderrPipe];
  }

  // Run the task
  [task launch];
  
  // Send data to stdin if necessary.
  if (input != nil) {
    [stdinHandle writeData:[input dataUsingEncoding: NSASCIIStringEncoding]];
    [stdinHandle closeFile];
  }
  
  // Grab the standard output and error
  NSData* stdoutData;
  if (stdoutLines != nil) {
    stdoutData = [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
  }

  NSData* stderrData;
  if (stderrChunks != nil) {
    stderrData = [[stderrPipe fileHandleForReading] readDataToEndOfFile];
  }
  
  // Wait for clean exit.
  [task waitUntilExit];
  
  if (stderrChunks != nil) {
    *stderrChunks = [[NSMutableArray alloc] init];
    
    // Parse stderr
    // FIXME: this is highly inefficient
    NSString* stderrString = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];
    for (NSString* line in [stderrString componentsSeparatedByString:@"\n"]) {
      NSMutableArray* toks = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:@" "]];
      // We only care about GNUPG states lines.
      if (toks.count == 0 || ![(NSString*)[toks firstObject] isEqualToString:@"[GNUPG:]"]) {
        continue;
      }
      
      NSString* text;
      if (toks.count > 2) {
        text = [[toks subarrayWithRange:NSMakeRange(2, toks.count - 2)] componentsJoinedByString:@" "];
      }
      
      [*stderrChunks addObject:[TPGPGOutputChunk makeWithKey:[toks objectAtIndex:1] andText:text]];
    }
  }
  
  // Parse stdout
  if (stdoutLines != nil) {
    NSString* stdoutString = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
    *stdoutLines = [NSMutableArray arrayWithArray:[stdoutString componentsSeparatedByString:@"\n"]];
  }
}


@end
