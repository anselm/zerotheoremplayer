
#import "ServerBrowser.h"

@implementation ServerBrowser

@synthesize servers,server,connection;

- (id)init {
    servers = [[NSMutableArray alloc] init];
    server = nil;
    connection = nil;
    return self;
}

- (void)dealloc {
    server = nil;
    [super dealloc];
}

- (BOOL)start {
    if ( netServiceBrowser != nil ) {
        [self stop];
    }
	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if( !netServiceBrowser ) {
		return NO;
	}
    [netServiceBrowser setDelegate:self];
	[netServiceBrowser searchForServicesOfType:@"_zerotheorem._tcp." inDomain:@""];
    return YES;
}

- (void)stop {
    if ( netServiceBrowser == nil ) {
        return;
    }
    [netServiceBrowser setDelegate:nil];
    [netServiceBrowser stop];
    [netServiceBrowser release];
    netServiceBrowser = nil;
    server = nil;
}

////////////////////////////////////////////////////////////////////////////////////
//other listeners
////////////////////////////////////////////////////////////////////////////////////

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"netservice did not publish");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"netservice did not resolve");
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSLog(@"netservice did update txt");
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"netservice did publish");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"netservice did resolve");
   // NSNotification* notification = [NSNotification notificationWithName:@"NetworkServiceFound" object:self];
   // [[NSNotificationCenter defaultCenter] postNotification:notification];

    //NSNotification* notification = [NSNotification notificationWithName:@"NetworkServiceFound" object:self];
    //[[NSNotificationCenter defaultCenter] postNotification:notification];
    if(!connection) {
        connection = [[Connection alloc] initWithNetService:server];
        connection.delegate = self;
        [connection connect];
    }

}

- (void)netServiceDidStop:(NSNetService *)sender {
    NSLog(@"netservice success");
}

- (void)netServiceWillPublish:(NSNetService *)sender {
    NSLog(@"netservice will publish");
}

- (void)netServiceWillResolve:(NSNetService *)sender {
    NSLog(@"netservice will resolve");
   // NSNotification* notification = [NSNotification notificationWithName:@"NetworkServiceFound" object:self];
   // [[NSNotificationCenter defaultCenter] postNotification:notification];
}

// Verifies [netService addresses]
- (BOOL)addressesComplete:(NSArray *)addresses
           forServiceType:(NSString *)serviceType
{
    NSLog(@"netservice addr complete");
    // Perform appropriate logic to ensure that [netService addresses]
    // contains the appropriate information to connect to the service
    return YES;
}

// Error handling code
- (void)handleError:(NSNumber *)error withService:(NSNetService *)service
{
    NSLog(@"An error occurred with service %@.%@.%@, error code = %@",
          [service name], [service type], [service domain], error);
    // Handle error here
}


////////////////////

- (void) connectionAttemptFailed:(Connection*)_connection {
    NSLog(@"Connection attempt failed");
}
- (void) connectionTerminated:(Connection*)_connection {
    NSLog(@"Connection Terminated");
    connection = nil;
}

- (void) receivedNetworkPacket:(NSDictionary*)message viaConnection:(Connection*)_connection {
    NSNotification* notification = [NSNotification notificationWithName:@"NetworkTrafficReceived" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

/////////////////////////////////////////////////////////////////////////////////////////////
// listening for changes to netservice state
/////////////////////////////////////////////////////////////////////////////////////////////

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    NSLog(@"network did find domain");
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    NSLog(@"network did remove domain");
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo {
    NSLog(@"network did not search");
}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {
    NSLog(@"network did stop search");
}
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
    NSLog(@"network will search");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    if (!server) {
        server = netService;
        [servers addObject:server];
        [server retain];
        [server setDelegate:self];
        [server resolveWithTimeout:20];
        NSLog(@"found network service %@",[server name]);
    } else {
        NSLog(@"found network unused service %@",[netService name]);
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    server = nil;
}

@end
