#import <Foundation/Foundation.h>

@interface GSAPortProtocol : NSURLProtocol
@end

// Global NSURLProtocol registration alone does not cover NSURLSession.
// Background sessions run elsewhere and cannot use custom protocol classes.
static NSURLSessionConfiguration *GSAPortSessionConfiguration(NSURLSessionConfiguration *configuration) {
    if (!configuration || configuration.identifier.length) return configuration;
    Class protocol = [GSAPortProtocol class];
    if ([configuration.protocolClasses containsObject:protocol]) return configuration;
    NSURLSessionConfiguration *copy = [configuration copy];
    NSMutableArray *protocols = [NSMutableArray arrayWithObject:protocol];
    if (copy.protocolClasses) [protocols addObjectsFromArray:copy.protocolClasses];
    copy.protocolClasses = protocols;
    return copy;
}

%hook NSURLSessionConfiguration

+ (NSURLSessionConfiguration *)defaultSessionConfiguration {
    return GSAPortSessionConfiguration(%orig);
}

+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration {
    return GSAPortSessionConfiguration(%orig);
}

%end

%hook NSURLSession

+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration {
    return %orig(GSAPortSessionConfiguration(configuration));
}

+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
                                delegate:(id<NSURLSessionDelegate>)delegate
                           delegateQueue:(NSOperationQueue *)queue {
    return %orig(GSAPortSessionConfiguration(configuration), delegate, queue);
}

%end
