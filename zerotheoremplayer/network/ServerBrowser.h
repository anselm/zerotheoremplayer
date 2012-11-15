
#import <Foundation/Foundation.h>
#import "Connection.h"

@interface ServerBrowser : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate, ConnectionDelegate> {
    NSNetServiceBrowser* netServiceBrowser;
    NSNetService* server;
    NSMutableArray* servers;
    Connection* connection; // my connection to the server - one only
    
    NSString* device_power; // some extended state
    NSString* device_state;
    NSString* device_name;

}
@property(nonatomic,retain) NSString* device_power;
@property(nonatomic,retain) NSString* device_state;
@property(nonatomic,retain) NSString* device_name;

@property(nonatomic,retain) NSMutableArray* servers;
@property(nonatomic,readonly) NSNetService* server;
@property(nonatomic,readonly) Connection* connection;
- (BOOL)start;
- (void)stop;
@end
