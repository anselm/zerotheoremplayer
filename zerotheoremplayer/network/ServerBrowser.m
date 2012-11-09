
#import "ServerBrowser.h"

@implementation ServerBrowser

@synthesize servers,server,connection;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// we begin by making a netservice browser - with all events being listened to here
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// after we start a netservice browser we now listen for services and will kick off a connection if we find one
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    if (!server && !connection) {
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
    if(server) {
        // XXX should I free memory
        [server stop];
        server = nil;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// after we found a server we attempt to connect to it and get an ordinary ip address so we can do an ordinary tcp connection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"netservice did not publish");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"netservice did not resolve");
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSLog(@"netservice did update txt");
}

- (void)netServiceWillPublish:(NSNetService *)sender {
    NSLog(@"netservice will publish");
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"netservice did publish");
}

- (void)netServiceWillResolve:(NSNetService *)sender {
    NSLog(@"netservice will resolve");
}

- (void) heartbeat:(NSTimer*)timer {
    // send our battery status periodically
    if(connection) {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: @"one", @"name", nil];
        [connection sendNetworkPacket:dict];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"netservice did resolve");
    if(!connection) {
        connection = [[Connection alloc] initWithNetService:server];
        connection.delegate = self;
        [connection connect];
        // start publishing a keepalive
    }

    // start publishing a heartbeat
///    if(connection) {
//        float timer=5.0;
//        [NSTimer scheduledTimerWithTimeInterval:timer target:self selector:@selector(heartbeat:) userInfo:nil repeats:YES];
//    }
    
}

- (void)netServiceDidStop:(NSNetService *)sender {
    NSLog(@"netservice has successfully finished");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// after we have a connection we basically just watch for any disconnects - or actual data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) connectionAttemptFailed:(Connection*)_connection {
    NSLog(@"Connection attempt failed");
    // connection will delete itself
    connection = 0;
}

- (void) connectionTerminated:(Connection*)_connection {
    NSLog(@"Connection terminated");
    // connection will delete itself
    connection = 0;
    // we kill server so that we start listening for new servers
    if(server) {
        // XXX should I free memory?
        [server stop];
        server = 0;
    }
}

- (void) receivedNetworkPacket:(NSDictionary*)dict viaConnection:(Connection*)_connection {
    NSNotification* notification = [NSNotification notificationWithName:@"NetworkTrafficReceived" object:self userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
