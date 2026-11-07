#import <Foundation/Foundation.h>

// NSURLSession may expose upload data through HTTPBodyStream instead of HTTPBody.
static NSURLRequest *GSAPortRequestWithBody(NSURLRequest *request, NSError **error) {
    if (request.HTTPBody || !request.HTTPBodyStream) return request;
    NSInputStream *stream = request.HTTPBodyStream;
    NSMutableData *body = [NSMutableData data];
    uint8_t buffer[4096];
    NSInteger count = 0;
    [stream open];
    while ((count = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
        if (body.length + (NSUInteger)count > 4 * 1024 * 1024) {
            [stream close];
            if (error) *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorDataLengthExceedsMaximum userInfo:nil];
            return nil;
        }
        [body appendBytes:buffer length:(NSUInteger)count];
    }
    NSError *streamError = stream.streamError;
    [stream close];
    if (count < 0 || streamError) {
        if (error) *error = streamError ?: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:nil];
        return nil;
    }
    NSMutableURLRequest *copy = [request mutableCopy];
    copy.HTTPBodyStream = nil;
    copy.HTTPBody = body;
    return copy;
}
