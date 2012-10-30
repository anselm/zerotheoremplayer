
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
//#include <CFNetwork/CFSocketStream.h>

#import "Server.h"
#import "Connection.h"

@interface Server ()
@property(nonatomic,assign) uint16_t port;
@property(nonatomic,retain) NSNetService* netService;
- (BOOL)createServer;
- (void)terminateServer;
- (BOOL)publishService;
- (void)unpublishService;
@end

@implementation Server

@synthesize port, netService;

- (void)dealloc {
    self.netService = nil;
    [super dealloc];
}

- (BOOL)start {
    if ( ! [self createServer] ) {
        return NO;
    }
    if ( ! [self publishService] ) {
        [self terminateServer];
        return NO;
    }
    return YES;
}

- (void)stop {
    [self terminateServer];
    [self unpublishService];
}

- (void)handleNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle {
    Connection* connection = [[[Connection alloc] initWithNativeSocketHandle:nativeSocketHandle] autorelease];
    
    if ( connection == nil ) {
        close(nativeSocketHandle);
        return;
    }
    
    if ( ! [connection connect] ) {
        [connection close];
        return;
    }    
}

static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    Server *server = (Server*)info;
    
    if ( type != kCFSocketAcceptCallBack ) return;
    
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;
    [server handleNewNativeSocket:nativeSocketHandle];
    NSLog(@"server accepted callback");
}


#pragma mark Sockets and streams

- (BOOL)createServer {
    
    CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
    
    listeningSocket = CFSocketCreate(
                                     kCFAllocatorDefault,
                                     PF_INET,        // The protocol family for the socket
                                     SOCK_STREAM,    // The socket type to create
                                     IPPROTO_TCP,    // The protocol for the socket. TCP vs UDP.
                                     kCFSocketAcceptCallBack,  // New connections will be automatically accepted and the callback is called with the data argument being a pointer to a CFSocketNativeHandle of the child socket.
                                     (CFSocketCallBack)&serverAcceptCallback,
                                     &socketCtxt );
    
    if ( listeningSocket == NULL ) {
        return NO;
    }
    
    int existingValue = 1;
    
    setsockopt( CFSocketGetNative(listeningSocket), SOL_SOCKET, SO_REUSEADDR, (void *)&existingValue, sizeof(existingValue));

    //// PART 2: Bind our socket to an endpoint.
    // We will be listening on all available interfaces/addresses.
    // Port will be assigned automatically by kernel.
    struct sockaddr_in socketAddress;
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sin_len = sizeof(socketAddress);
    socketAddress.sin_family = AF_INET;   // Address family (IPv4 vs IPv6)
    socketAddress.sin_port = 0;           // Actual port will get assigned automatically by kernel
    socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);    // We must use "network byte order" format (big-endian) for the value here
    
    // Convert the endpoint data structure into something that CFSocket can use
    NSData *socketAddressData = [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
    
    // Bind our socket to the endpoint. Check if successful.
    if ( CFSocketSetAddress(listeningSocket, (CFDataRef)socketAddressData) != kCFSocketSuccess ) {
        if ( listeningSocket != NULL ) {
            CFRelease(listeningSocket);
            listeningSocket = NULL;
        }
        return NO;
    }
    
    
    //// PART 3: Find out what port kernel assigned to our socket
    // We need it to advertise our service via Bonjour
    NSData *socketAddressActualData = [(NSData *)CFSocketCopyAddress(listeningSocket) autorelease];
    
    // Convert socket data into a usable structure
    struct sockaddr_in socketAddressActual;
    memcpy(&socketAddressActual, [socketAddressActualData bytes],[socketAddressActualData length]);
    
    self.port = ntohs(socketAddressActual.sin_port);
    
    //// PART 4: Hook up our socket to the current run loop
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, listeningSocket, 0);
    CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
    
    NSLog(@"server should be running now");
    return YES;
}

- (void) terminateServer {
    if ( listeningSocket != nil ) {
        CFSocketInvalidate(listeningSocket);
		CFRelease(listeningSocket);
		listeningSocket = nil;
    }
    NSLog(@"server stopped");
}


#pragma mark Bonjour

- (BOOL) publishService {
    NSString* chatRoomName = @"zerotheorem";
 	self.netService = [[NSNetService alloc]  initWithDomain:@"" type:@"_chatty._tcp." name:chatRoomName port:self.port];
	if (self.netService == nil) return NO;
	[self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[self.netService publish];
    NSLog(@"server publishing");
    return YES;
}


- (void) unpublishService {
  if ( self.netService ) {
		[self.netService stop];
		[self.netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		self.netService = nil;
	}
    NSLog(@"server unpublishing");
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict {
    if ( sender != self.netService ) return;
    [self terminateServer];
    [self unpublishService];
    NSLog(@"server stopping");
}

@end

