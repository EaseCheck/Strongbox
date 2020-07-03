//
//  AesInputStream.m
//  Strongbox
//
//  Created by Strongbox on 10/06/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import "AesInputStream.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Utils.h"
#import "Constants.h"

@interface AesInputStream ()

@property NSInputStream* inputStream;
@property CCCryptorRef *cryptor;
@property uint8_t* workChunk;
@property size_t workChunkLength;
@property size_t workingChunkOffset;
@property size_t readFromStreamTotal;
@property size_t writtenSoFar;
@property size_t writtenToStreamSoFar;

@property NSError* error;

@end

@implementation AesInputStream

- (instancetype)initWithStream:(NSInputStream*)inputStream key:(NSData*)key iv:(NSData*)iv {
    self = [super init];
    if (self) {
        self.inputStream = inputStream;
        
        _cryptor = malloc(sizeof(CCCryptorRef));
        
        CCCryptorStatus status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, _cryptor);
        if (status != kCCSuccess) {
            NSLog(@"Crypto Error: %d", status);
            return nil;
        }
        self.workingChunkOffset = 0;
        self.workChunk = nil;
        self.workChunkLength = 0;
    }
    return self;
}

- (void)open {
    [self.inputStream open];
}

- (void)close {
    [self.inputStream close];
    
    if (self.workChunk) {
        free(self.workChunk);
        self.workChunk = nil;
    }

    if (self.cryptor) {
        CCCryptorRelease(*_cryptor);
        free(_cryptor);
        self.cryptor = nil;
    }
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (self.workChunk != nil && self.workChunkLength == 0) { // EOF
        return 0L;
    }
    
    size_t bufferOffset = 0;
    size_t bufferWritten = 0;
        
    while ( bufferWritten < len ) {
        size_t workingAvailable = self.workChunkLength - self.workingChunkOffset;

        if (workingAvailable == 0) {
            [self loadNextWorkingChunk];
        
            if (self.workChunk == nil) {
                return -1L;
            }
        
            workingAvailable = self.workChunkLength - self.workingChunkOffset;
            if (workingAvailable == 0) {
                return bufferWritten; // EOS
            }
        }

        size_t bufferAvailable = len - bufferOffset;
        size_t bytesToWrite = MIN(workingAvailable, bufferAvailable);

        uint8_t* src = &self.workChunk[self.workingChunkOffset];
        uint8_t* dst = &buffer[bufferOffset];

        memcpy(dst, src, bytesToWrite);
    
        self.writtenToStreamSoFar += bytesToWrite;
        //NSLog(@"DEBUG: Written to stream so far: %zu", self.writtenToStreamSoFar);

        bufferWritten += bytesToWrite;
        bufferOffset += bytesToWrite;
        self.workingChunkOffset += bytesToWrite;
    }
        
    return bufferWritten;
}

- (void)loadNextWorkingChunk {
    self.workChunkLength = 0;
    self.workingChunkOffset = 0;
    
    uint8_t *block = malloc(kStreamingSerializationChunkSize);
    NSInteger bytesRead = [self.inputStream read:block maxLength:kStreamingSerializationChunkSize];
    if (bytesRead < 0) {
        self.error = self.inputStream.streamError;
        self.workChunk = nil;
        self.workChunkLength = 0;
        free(block);
        return;
    }
    
    self.readFromStreamTotal += bytesRead;

    if (self.workChunk == nil) {
        self.workChunk = malloc(kStreamingSerializationChunkSize);
    }
    
    if (bytesRead == 0) {
        CCCryptorStatus status = CCCryptorFinal(*self.cryptor, self.workChunk, kStreamingSerializationChunkSize, &_workChunkLength);
        if (status != kCCSuccess) {
            size_t req = CCCryptorGetOutputLength(*self.cryptor, bytesRead, YES);
            if (status == kCCBufferTooSmall && req == 0) { // Weird and sporadic but safe to ignore... :/ - MMcG - 20-Jun-2020
//                NSLog(@"Not really a crypto Error: %d-%zu", status, req);
            }
            else {
                NSLog(@"Crypto Error: %d-%zu", status, req);
                self.error = [Utils createNSError:@"AES: Crypto Error" errorCode:status];
                self.workChunk = nil;
                self.workChunkLength = 0;
                free(block);
                return;
            }
        }
        
        self.writtenSoFar += self.workChunkLength;
        // NSLog(@"DECRYPT FINAL: bytesRead = %zu, decWritten = %zu, totalRead = [%zu], writtenSoFar = %zu", bytesRead, self.workChunkLength, self.readFromStreamTotal, self.writtenSoFar);
    }
    else {
        CCCryptorStatus status = CCCryptorUpdate(*self.cryptor, block, bytesRead, self.workChunk, kStreamingSerializationChunkSize, &_workChunkLength);
        
        if (status != kCCSuccess) {
            NSLog(@"Crypto Error: %d", status);
            self.error = [Utils createNSError:@"AES: Crypto Error" errorCode:status];
            self.workChunk = nil;
            self.workChunkLength = 0;
            free(block);
            return;
        }

        self.writtenSoFar += self.workChunkLength;
        //NSLog(@"DECRYPT: bytesRead = %zu, decWritten = %zu, totalRead = [%zu], writtenSoFar = %zu", bytesRead, self.workChunkLength, self.readFromStreamTotal, self.writtenSoFar);
    }
    
    free(block);
}

- (NSError *)streamError {
    return self.error;
}

@end
