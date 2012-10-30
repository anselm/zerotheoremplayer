
#import <Foundation/Foundation.h>

@interface Server : NSObject {
    uint16_t port;
    CFSocketRef listeningSocket;
    NSNetService* netService;
}

- (BOOL)start;
- (void)stop;

@end
