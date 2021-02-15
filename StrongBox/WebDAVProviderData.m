//
//  WebDAVProviderData.m
//  Strongbox
//
//  Created by Mark on 11/12/2018.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "WebDAVProviderData.h"

@implementation WebDAVProviderData

- (NSDictionary *)serializationDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self.sessionConfiguration serializationDictionary]];
    [dict setObject:self.href forKey:@"href"];
    
    return dict;
}

+ (instancetype)fromSerializationDictionary:(NSDictionary *)dictionary {
    WebDAVProviderData *pd = [[WebDAVProviderData alloc] init];
    
    pd.href = [dictionary objectForKey:@"href"];
    pd.sessionConfiguration = [WebDAVSessionConfiguration fromSerializationDictionary:dictionary];
    
    return pd;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"href: [%@]", self.href];
}

@end
