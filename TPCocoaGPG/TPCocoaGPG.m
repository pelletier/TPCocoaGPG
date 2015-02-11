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
  NSArray* stdoutLines;
  NSData* stdoutData;
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
  [self execCommand:args withInput:nil stderrChunks:nil stdoutData:&stdoutData andError:&error];
  // Parse stdout
  NSString* stdoutString = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
  stdoutLines = [stdoutString componentsSeparatedByString:@"\n"];

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
  if (key != nil && key.length > 0) {
    [self execCommand:@[@"--import"] withInput:[key dataUsingEncoding:NSUTF8StringEncoding] stderrChunks:nil stdoutData:nil andError:nil];
  }
}

- (BOOL)checkIfPassphrase:(NSString*)passphrase unlocksKey:(TPGPGKey*)key {
  if (key == nil) {
    return NO;
  }
  NSArray* args = @[@"--batch",
                    @"--passphrase-fd", @"0",
                    @"--no-use-agent",
                    @"--local-user", key.keyId,
                    @"--sign",
                    @"--armor"];
  NSString* input = [NSString stringWithFormat:@"%@\nThis is a random string\n", passphrase];
  NSMutableArray* stderrChunks;
  [self execCommand:args withInput:[input dataUsingEncoding:NSUTF8StringEncoding] stderrChunks:&stderrChunks stdoutData:nil andError:nil];
  for (TPGPGOutputChunk* chunk in stderrChunks) {
    if ([chunk.key isEqualToString:@"GOOD_PASSPHRASE"]) {
      return YES;
    }
  }
  return NO;
}

- (NSString*)generateKeysWithLength:(int)length
                              email:(NSString*)email
                               name:(NSString*)name
                            comment:(NSString*)comment
                      andPassphrase:(NSString*)passphrase {
  if (!(length == 1024 || length == 2048)) {
    NSLog(@"TPCocoaGPG: bad key length for generation: %d", length);
    return nil;
  }
  assert(email);
  assert(name);
  assert(comment);
  assert(passphrase);
  
  NSDictionary* keyParams = @{@"Key-Length": [NSString stringWithFormat:@"%d", length],
                              @"Name-Real": name,
                              @"Name-Comment": comment,
                              @"Name-Email": email,
                              @"Expire-Date": @"0",
                              @"Passphrase": passphrase};
  NSMutableArray* inputLines = [NSMutableArray arrayWithObject:@"Key-Type: RSA"];
  for (NSString* key in keyParams.allKeys) {
    [inputLines addObject:[NSString stringWithFormat:@"%@: %@", key, keyParams[key]]];
  }
  [inputLines addObject:@"\%commit;"];
  NSString* input = [inputLines componentsJoinedByString:@"\n"];
  NSArray* args = @[@"--gen-key", @"--batch"];
  NSMutableArray* stderrChunks;
  [self execCommand:args withInput:[input dataUsingEncoding:NSUTF8StringEncoding] stderrChunks:&stderrChunks stdoutData:nil andError:nil];
  NSString* fingerprint = nil;
  for (TPGPGOutputChunk* chunk in stderrChunks) {
    if ([chunk.key isEqualToString:@"KEY_CREATED"]) {
      fingerprint = [chunk.text componentsSeparatedByString:@" "][1];
      break;
    }
  }
  return fingerprint;
}


- (NSData*)exportKey:(TPGPGKey*)key {
  if (!key) {
    return nil;
  }
  NSArray* args;
  if ([[key getValue:kTPCocoaGPGTypeKey] isEqualToString:@"sec"]) {
    args = @[@"--export-secret-key", @"-a", [key getValue:kTPCocoaGPGKeyIdKey]];
  } else {
    args = @[@"--export", @"-a", [key getValue:kTPCocoaGPGKeyIdKey]];
  }
  NSMutableData* data;
  [self execCommand:args withInput:nil stderrChunks:nil stdoutData:&data andError:nil];
  return data;
}

#pragma mark Encryption

- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key {
  return [self encryptData:data withKey:key andPassphrase:nil];
}

- (NSData*)encryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase {
  if (key == nil) {
    return nil;
  }
  // FIXME: don't hardcode recipient to self.
  NSArray* args = @[@"--encrypt",
                    @"--recipient", key.keyId,
                    @"--armor",
                    @"--batch",
                    @"--passphrase-fd", @"0",
                    @"--no-use-agent",
                    @"--local-user", key.keyId,
                    @"--always-trust"];
  NSData* input = [self prependPassphrase:passphrase toData:data];
  NSData* stdoutData;
  [self execCommand:args withInput:input stderrChunks:nil stdoutData:&stdoutData andError:nil];
  return stdoutData;
}

- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key andPassphrase:(NSString*)passphrase {
  if (key == nil) {
    return nil;
  }
  // FIXME: don't hardcode recipient to self.
  NSArray* args = @[@"--decrypt",
                    @"--armor",
                    @"--batch",
                    @"--passphrase-fd", @"0",
                    @"--no-use-agent",
                    @"--local-user", key.keyId,
                    @"--always-trust"];
  NSData* input = [self prependPassphrase:passphrase toData:data];
  NSData* stdoutData;
  [self execCommand:args withInput:input stderrChunks:nil stdoutData:&stdoutData andError:nil];
  return stdoutData;
}

- (NSData*)decryptData:(NSData*)data withKey:(TPGPGKey*)key {
  return [self decryptData:data withKey:key andPassphrase:nil];
}

#pragma mark - Private helpers

- (NSData*)prependPassphrase:(NSString*)passphrase toData:(NSData*)data {
  if (passphrase == nil) {
    return data;
  }
  NSMutableData* buffer = [NSMutableData dataWithData:[[NSString stringWithFormat:@"%@\n", passphrase] dataUsingEncoding:NSUTF8StringEncoding]];
  [buffer appendData:data];
  return buffer;
}

- (void)execCommand:(NSArray*)commands
          withInput:(NSData*)input
       stderrChunks:(NSMutableArray**)stderrChunks
         stdoutData:(NSData**)stdoutData
           andError:(NSError**)error {
  // Prepare boolean values as shortcuts for later.
  BOOL grabStdout = (stdoutData != nil);
  BOOL grabStderr = (stderrChunks != nil);
  BOOL provideStdin = (input != nil);
  
  // Add necessary arguments to make GPG usable as a child process.
  NSMutableArray* args = [NSMutableArray arrayWithArray:@[@"--verbose", @"--status-fd", @"2", @"--no-tty", @"--homedir", _home]];
  [args addObjectsFromArray:commands];

  // Prepare the NSTask to run GPG as a child process.
  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:_gpgPath];
  [task setArguments:args];
  
  // Prepare pipe for stdout reading if needed.
  NSFileHandle* stdoutFileHandle;
  if (grabStdout) {
    NSPipe* stdoutPipe = [NSPipe pipe];
    [task setStandardOutput:stdoutPipe];
    stdoutFileHandle = [stdoutPipe fileHandleForReading];
  }
  
  // Prepare pipe for stderr reading if needed.
  NSFileHandle* stderrFileHandle;
  if (grabStderr) {
    NSPipe* stderrPipe = [NSPipe pipe];
    [task setStandardError:stderrPipe];
    stderrFileHandle = [stderrPipe fileHandleForReading];
  }
  
  // Prepare pipe for stdin writing if needed.
  NSFileHandle* stdinFileHandle;
  if (provideStdin) {
    NSPipe* stdinPipe = [NSPipe pipe];
    [task setStandardInput:stdinPipe];
    stdinFileHandle = [stdinPipe fileHandleForWriting];
  }
  
  // Start child process and continue.
  [task launch];
  
  // Create a dispatch group to easily send async tasks (read stderr / write stdin) and wait for
  // them at the end.
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_group_t group = dispatch_group_create();

  // If required, launch an async task to write to the stdin pipe.
  if (provideStdin) {
    dispatch_group_async(group, queue, ^{
      [stdinFileHandle writeData:input];
      [stdinFileHandle closeFile];
    });
  }
  
  // If required, launch an async task to read the stderr pipe.
  __block NSData* rawStderrData;
  if (grabStderr) {
    dispatch_group_async(group, queue, ^{
      rawStderrData = [stderrFileHandle readDataToEndOfFile];
    });
  }

  // If required, use the current thread to read the stdout pipe.
  if (grabStdout) {
    *stdoutData = [stdoutFileHandle readDataToEndOfFile];
  }
  
  // Wait for possible async tasks to run.
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  // Ensure the task has really finished.
  [task waitUntilExit];

  if (grabStderr) {
    *stderrChunks = [[NSMutableArray alloc] init];
    
    // Parse stderr
    // FIXME: this is highly inefficient
    NSString* stderrString = [[NSString alloc] initWithData:rawStderrData encoding:NSUTF8StringEncoding];
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
}

@end
