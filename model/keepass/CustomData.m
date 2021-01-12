//
//  CustomData.m
//  Strongbox
//
//  Created by Strongbox on 02/11/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import "CustomData.h"
#import "KeePassConstants.h"
#import "CustomDataItem.h"

@implementation CustomData

- (instancetype)initWithContext:(XmlProcessingContext*)context {
    return [self initWithXmlElementName:kCustomDataElementName context:context];
}

- (instancetype)initWithXmlElementName:(NSString *)xmlElementName context:(XmlProcessingContext*)context {
    if(self = [super initWithXmlElementName:xmlElementName context:context]) {
        self.dictionary = @{}.mutableCopy;
    }
    
    return self;
}

- (id<XmlParsingDomainObject>)getChildHandler:(nonnull NSString *)xmlElementName {
    if([xmlElementName isEqualToString:kCustomDataItemElementName]) {
        return [[CustomDataItem alloc] initWithXmlElementName:kCustomDataItemElementName context:self.context];
    }
    
    return [super getChildHandler:xmlElementName];
}

- (BOOL)addKnownChildObject:(id<XmlParsingDomainObject>)completedObject withXmlElementName:(nonnull NSString *)withXmlElementName {
    if([withXmlElementName isEqualToString:kCustomDataItemElementName]) {
        CustomDataItem* item = (CustomDataItem*)completedObject;
        self.dictionary[item.key] = item.value;
        return YES;
    }
    
    return NO;
}

- (BOOL)writeXml:(id<IXmlSerializer>)serializer {
    if(![serializer beginElement:self.originalElementName
                            text:self.originalText
                      attributes:self.originalAttributes]) {
        return NO;
    }
    
    for (NSString* key in self.dictionary.allKeys) {
        NSString* value = self.dictionary[key];
        
        if(![serializer beginElement:kCustomDataItemElementName]) return NO;

        

        if(![serializer writeElement:kKeyElementName text:key attributes:nil trimWhitespace:NO]) return NO;
        if(![serializer writeElement:kValueElementName text:value attributes:nil trimWhitespace:NO]) return NO;
        
        [serializer endElement];
    }
        
    if(![super writeUnmanagedChildren:serializer]) {
        return NO;
    }
    
    [serializer endElement];
    
    return YES;
}

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[CustomData class]]) {
        return NO;
    }
    
    CustomData* other = (CustomData*)object;
    
    if(![self.dictionary isEqualToDictionary:other.dictionary]) {
        return NO;
    }

    return YES;
}

@end
