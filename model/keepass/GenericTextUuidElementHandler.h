//
//  GenericTextUuidElementHandler.h
//  Strongbox
//
//  Created by Mark on 21/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "BaseXmlDomainObjectHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface GenericTextUuidElementHandler : BaseXmlDomainObjectHandler

- (instancetype)initWithXmlElementName:(NSString*)xmlElementName context:(XmlProcessingContext*)context NS_DESIGNATED_INITIALIZER;

@property (nullable) NSUUID *uuid;

@end

NS_ASSUME_NONNULL_END
