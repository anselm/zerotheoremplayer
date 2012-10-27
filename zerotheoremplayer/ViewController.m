
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// av player utils
/////////////////////////////////////////////////////////////////////////////////////////////

@interface PlayerView : UIView
@property (nonatomic, retain) AVPlayer *player;
@end

@implementation PlayerView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end

@implementation ViewController

NSString* serverurl = 0;
NSURL* playme = 0;

/////////////////////////////////////////////////////////////////////////////////////////////
// find a file
/////////////////////////////////////////////////////////////////////////////////////////////

- (NSURL*)findFile:(NSString*) findme {
    
    NSArray* dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docsDir = [dirPaths objectAtIndex:0];
    NSFileManager *filemgr =[NSFileManager defaultManager];
    
    if ([filemgr changeCurrentDirectoryPath: docsDir] == NO) {
        NSLog(@"could not find this");
        return 0;
    }
    
    NSString *filepath   = nil; //   [[NSBundle mainBundle] pathForResource:@"stage-3_04_comp_V05_counter" ofType:@"mov"];
    
    NSArray *filelist = [filemgr contentsOfDirectoryAtPath:docsDir error:NULL];
    for(NSString* filename in filelist) {
        //NSLog(@"Looking at local file %@",filename);
        //NSLog(@"Does it match request %@",findme);
        if(!findme || [filename isEqualToString:findme]) {
            filepath = [docsDir stringByAppendingPathComponent:filename];
            //NSLog(@"1 found %@ ",filename);
            //NSArray* parts = [filename componentsSeparatedByString:@"."];
            //NSLog(@"found %@ and %@", parts[0], parts[1]);
            //filepath = [[NSBundle mainBundle] pathForResource:parts[0] ofType:parts[1]];
            //break;
        }
    }
    
    if(!filepath) return 0;
    
    NSString* webName = [filepath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"2 found encoded %@", webName);
    
    NSURL    *fileURL    =   [NSURL fileURLWithPath:webName];
    
    return fileURL;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// network scanner
/////////////////////////////////////////////////////////////////////////////////////////////

NSURLRequest* request;
NSURLConnection* connection;
NSMutableData* responseData = nil;
NSString* lastcommand = 0;
int poll_count = 0;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    responseData = [[NSMutableData alloc] init];
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // rekick polling
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(pollNetwork:) userInfo:nil repeats:NO];
    [responseData release];
    //[connection release];
    //[request release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *myError = nil;
    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&myError];
    for(NSString* key in res) {
        NSString *val = [res objectForKey: key];
        if([key isEqualToString:@"url"] && val.length > 1) {
            if(![val isEqualToString:lastcommand]) {
                lastcommand = [val copy];
                if([val hasPrefix:@"http"]) {
                    playme = [NSURL URLWithString:val];
                } else {
                    playme = [self findFile:val];
                }
                if(playme) {
                    NSLog(@"network requestiong to play %@",playme);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
                } else {
                    NSLog(@"network cannot find requested file %@",val);
                }
            }
            break;
        }
    }
    [responseData release];
    //[connection release];
    //[request release];
    // wait a bit and then poll again
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(pollNetwork:) userInfo:nil repeats:NO];
}

- (void)pollNetwork:(id)sender {
    NSString* blah = [NSString stringWithFormat:@"%@?poll=%d",serverurl,poll_count];
    NSURL* url = [NSURL URLWithString:blah];
    request = [NSURLRequest requestWithURL: [NSURL URLWithString:blah]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSLog(@"polling again %d %@",poll_count,url); poll_count++;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// movie play
/////////////////////////////////////////////////////////////////////////////////////////////

MPMoviePlayerController *moviePlayer;
UIScreen* external_disp;
UIWindow* external_window;
AVPlayer *player;
AVPlayerItem *playerItem;
AVPlayerLayer *playerLayer;
CMTime duration;

- (void)moviePlaybackComplete:(NSNotification *)notification {
    //MPMoviePlayerController *moviePlayer = [notification object];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerControllerPlaybackDidFinishNotification object:moviePlayer];
    [moviePlayer.view removeFromSuperview];
    [moviePlayer release];
}

-(void)playMovie:(NSURL*) filepathurl {

    if(!filepathurl)return;
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // bad ideas
    /////////////////////////////////////////////////////////////////////////////////////////////

    // This approach is slow and or fails to copy opengl
    //    [[TVOutManager sharedInstance] startTVOut];

/*
    This approach lacks any kind of high fidelity control
    UIWebView* videoView;
 
    CGRect bounds = [[UIScreen mainScreen] bounds];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString* html = @"<video src=\"big-buck-bunny-clip.m4v\" width=640 height-480 control controls fullscreen allowFullScreen autoplay loop></video>";
    if (videoView == nil) {
        videoView = [[UIWebView alloc] initWithFrame:bounds];
        [self.view addSubview:videoView];
    }
    [videoView loadHTMLString:html baseURL:[bundle resourceURL]];
    if(1)return;
*/

    /////////////////////////////////////////////////////////////////////////////////////////////
    // better
    /////////////////////////////////////////////////////////////////////////////////////////////

    if (!external_window && [[UIScreen screens] count] > 1) {
        UIScreenMode* best = 0;
        external_disp = [[UIScreen screens] objectAtIndex:1];
        for(UIScreenMode* obj in [external_disp availableModes]) {
            NSLog(@"display size %f,%f",obj.size.width,obj.size.height);
            if(!best || obj.size.width > best.size.width) best = obj;
        }
        [external_disp setCurrentMode:best];
        external_window = [[UIWindow alloc] init];
        external_window.screen = external_disp;
        [external_window makeKeyAndVisible];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    // start or restart movie player
    // http://stackoverflow.com/questions/4560065/MPMoviePlayerController-switching-movies-causes-white-flash
    /////////////////////////////////////////////////////////////////////////////////////////////

    if(0) {
        MPMoviePlayerController* old = moviePlayer;
        
        if(old) {
            //old.scalingMode = MPMovieScalingModeNone;
            //[old setFullscreen:NO];
            [old.view removeFromSuperview];
            [old stop];
            [old release];
        }

        moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:filepathurl];
        
        if(external_window) {
            [external_window addSubview:moviePlayer.view];
        } else {
            CGRect bounds = [[UIScreen mainScreen] bounds];
            if(bounds.size.width < bounds.size.height) {
                float temp = bounds.size.width;
                bounds.size.width = bounds.size.height;
                bounds.size.height = temp;
            }
            [moviePlayer.view setFrame:bounds];
            [self.view addSubview:moviePlayer.view];
        }

        /////////////////////////////////////////////////////////////////////////////////////////////
        // play movie now
        /////////////////////////////////////////////////////////////////////////////////////////////
        
        [moviePlayer setControlStyle:MPMovieControlStyleNone];
        //moviePlayer.controlStyle = MPMovieControlStyleNone;
        //[moviePlayer setFullscreen:YES];
        moviePlayer.fullscreen = YES;
        moviePlayer.scalingMode = MPMovieScalingModeFill;
        moviePlayer.repeatMode = 1;
        [moviePlayer play];
        NSLog(@"playing a new movie %@",filepathurl);
        
    } else {

        if(!player) {
            AVAsset *asset = [AVURLAsset URLAssetWithURL:filepathurl options:nil];
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            player = [[AVPlayer playerWithPlayerItem:playerItem] retain];
            duration = player.currentItem.asset.duration;

            CGRect bounds = [self.view bounds];
            if(external_window) {
                bounds = [external_window bounds];
            }
            UIView *newView = [[UIView alloc] initWithFrame:bounds];
            newView.backgroundColor = [UIColor blackColor];
            
            AVPlayerLayer *avPlayerLayer = [[AVPlayerLayer playerLayerWithPlayer:player] retain];
            [avPlayerLayer setFrame:bounds];
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            NSLog(@"bounds are %f,%f",bounds.size.width,bounds.size.height);
            [newView.layer addSublayer:avPlayerLayer];
            if(!external_window) {
                [self.view addSubview:newView];
            } else {
                [external_window addSubview:newView];
            }
        } else {
            [player pause];
            AVAsset *asset = [AVURLAsset URLAssetWithURL:filepathurl options:nil];
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        }

        [player play];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[player currentItem]];

        

//        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;


        //[player pause];
        //[player replaceCurrentItemWithPlayerItem:newPlayerItem];

        // [asset load];

    }

}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

/////////////////////////////////////////////////////////////////////////////////////////////
// startup
/////////////////////////////////////////////////////////////////////////////////////////////

- (void) playNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"Play"]) {
        if(playme) {
            // play requested file
            [self playMovie:playme];
        }
    }
}

- (id)initWithURL:(NSString *)url {
    self = [super init];
    serverurl = url;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNotification:) name:@"Play" object:nil];
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(serverurl && serverurl.length > 1) {
        // preferentially try to visit url to get commands to run
        [self pollNetwork:self];
    } else {
        // if no file supplied by network try play first file
        playme = [self findFile:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(moviePlayer) {
        if(moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            [moviePlayer pause];
            NSLog(@"pausing movie");
        } else {
            [moviePlayer play];
            NSLog(@"playing movie");
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}


@end