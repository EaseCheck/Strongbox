//
//  Kdb1DatabaseMetadata.m
//  Strongbox
//
//  Created by Mark on 09/11/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "Kdb1DatabaseMetadata.h"
#import "KeePassConstants.h"

static const uint32_t kDefaultVersion = 0x00030004;

@implementation Kdb1DatabaseMetadata

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.flags = kFlagsAes | kFlagsSha2;
        self.version = kDefaultVersion;
        self.transformRounds = kDefaultTransformRounds;
    }
    
    return self;
}

- (BasicOrderedDictionary<NSString*, NSString*>*)kvpForUi {
    BasicOrderedDictionary<NSString*, NSString*>* kvps = [[BasicOrderedDictionary alloc] init];
    
    [kvps addKey:NSLocalizedString(@"database_metadata_field_format", @"Database Format") andValue:@"KeePass 1"];
    [kvps addKey:NSLocalizedString(@"database_metadata_field_outer_encryption", @"Outer Encryption") andValue:((self.flags & kFlagsAes) == kFlagsAes) ? @"AES-256" : @"TwoFish"];
    [kvps addKey:NSLocalizedString(@"database_metadata_field_transform_rounds", @"Transform Rounds") andValue:[NSString stringWithFormat:@"%u", self.transformRounds]];
    
    return kvps;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self kvpForUi]];
}

@end
