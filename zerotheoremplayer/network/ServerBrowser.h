
#import <Foundation/Foundation.h>
#import "Connection.h"

@interface ServerBrowser : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate, ConnectionDelegate> {
    NSNetServiceBrowser* netServiceBrowser;
    NSNetService* server;
    NSMutableArray* servers;
    Connection* connection;
}
@property(nonatomic,retain) NSMutableArray* servers;
@property(nonatomic,readonly) NSNetService* server;
@property(nonatomic,readonly) Connection* connection;
- (BOOL)start;
- (void)stop;
@end
