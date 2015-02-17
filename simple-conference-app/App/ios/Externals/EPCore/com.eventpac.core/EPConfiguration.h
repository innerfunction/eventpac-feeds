//
//  EPConfiguration.h
//  EventPacComponents
//
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFResource.h"
#import "IFJSONData.h"
#import "EPValues.h"

@class EPConfiguration;

@interface EPConfigurationPropertyHandler : IFJSONPropertyHandler {
    EPConfiguration *parent;
}

- (id)initWithConfiguration:(EPConfiguration *)_parent;

@end

// A class for reading component configurations.
// Intended use is for accessing configuration values read from a JSON file.
// The class is a thin wrapper around an IFValues instance.
@interface EPConfiguration : NSObject <EPValues> {
    EPConfigurationPropertyHandler *propertyHandler;
}

@property (nonatomic, strong) id data;
@property (nonatomic, strong) EPConfiguration *root;
@property (nonatomic, strong) IFResource *resource;
@property (nonatomic, strong) NSDictionary *context;

// Initialize the configuration with the specified data.
- (id)initWithData:(id)data;
// Initialize the configuration with the specified data and parent configuraiton.
- (id)initWithData:(id)data parent:(EPConfiguration *)parent;
// Initialize the configuration with the specified data and resource.
- (id)initWithData:(id)data resource:(IFResource *)resource;
// Initialize the configuration by reading JSON from the specified resource.
- (id)initWithResource:(IFResource *)resource;
// Initialize the configuration using the specified data and the specified base resource.
- (id)initWithResource:(IFResource *)resource parent:(EPConfiguration *)parent;

// Return the name property as the specified representation.
- (id)getValue:(NSString *)key asRepresentation:(NSString*)representation;

// Return the named property as a URI resource.
- (IFResource *)getValueAsResource:(NSString *)name;

// Return the named property as typed values.
- (EPConfiguration *)getValueAsConfiguration:(NSString *)name;
- (EPConfiguration *)getValueAsConfiguration:(NSString *)name defaultValue:(EPConfiguration *)defaultValue;

// Return the named property as a list of configurations.
- (NSArray *)getValueAsConfigurationList:(NSString *)name;

// Return the named property as a map (i.e. dictionary) of configuration objects.
// This assumes that the named property has an object value in the underlying JSON. The value of each property
// on this object should in turn be capable of resolving to a configuration object.
- (NSDictionary *)getValueAsConfigurationMap:(NSString *)name;

// Merge this values object with the provided argument and return the result.
// Values in the argument are copied over the current values object.
- (EPConfiguration *)mergeConfiguration:(EPConfiguration *)otherConfig;

// Extend this configuration with the specified set of parameters.
- (EPConfiguration *)extendWithParameters:(NSDictionary *)params;

// Normalize this configuration by flattening "config" properties and resolving "extends" properties.
- (EPConfiguration *)normalize;

// Flatten the configuration by merging its "config" property (if any) into the top level properties.
- (EPConfiguration *)flatten;

+ (EPConfiguration *)emptyConfiguration;

@end
