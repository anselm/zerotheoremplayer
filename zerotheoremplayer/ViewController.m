
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "ServerBrowser.h"
#import "Connection.h"

extern bool useavplayer;
extern bool useexternal;
extern int fillmode;
extern int loopmode;
NSString* defaultFile = 0;
int nloops = 0;

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
// http network scanner
/////////////////////////////////////////////////////////////////////////////////////////////

NSString* serverurl = 0;
NSURL* playme = 0;
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
                    if(!playme) {
                        playme = [self findFile:0];
                    }
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
    //NSURL* url = [NSURL URLWithString:blah];
    request = [NSURLRequest requestWithURL: [NSURL URLWithString:blah]];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    //NSLog(@"polling again %d %@",poll_count,url); poll_count++;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// movie play
/////////////////////////////////////////////////////////////////////////////////////////////

MPMoviePlayerController *moviePlayer;
UIScreen* external_screen;
UIWindow* external_window;
AVPlayer *player;
AVPlayerItem *playerItem;
AVPlayerLayer *playerLayer;
CMTime duration;


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if(player) {
        nloops++;
        //    if(loopmode) {
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
        //   }
    }
}

- (void)moviePlaybackComplete:(NSNotification *)notification {
    nloops++;
    if(moviePlayer) {
        if(!loopmode) {
            // because the end of some movies is not black
            [moviePlayer setCurrentPlaybackTime:0];
        }
        //MPMoviePlayerController *moviePlayer = [notification object];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerControllerPlaybackDidFinishNotification object:moviePlayer];
        //[moviePlayer.view removeFromSuperview];
        //[moviePlayer release];
        int reason = [[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
        if(reason == MPMovieFinishReasonPlaybackEnded) {
            NSLog(@"Reason: MPMovieFinishReasonPlaybackEnded");
        }
        else if(reason == MPMovieFinishReasonPlaybackError) {
            NSLog(@"Reason: MPMovieFinishReasonPlaybackError");
        }
        else if(reason == MPMovieFinishReasonUserExited) {
            NSLog(@"Reason: MPMovieFinishReasonUserExited");
        }
        else {
            NSLog(@"Reason: %d", reason);
        }
    }
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

    if (useexternal && !external_window && [[UIScreen screens] count] > 1) {
        UIScreenMode* best = 0;
        external_screen = [[UIScreen screens] objectAtIndex:1];
        for(UIScreenMode* obj in [external_screen availableModes]) {
            //NSLog(@"display size %f,%f",obj.size.width,obj.size.height);
            if(!best || obj.size.width > best.size.width) best = obj;
        }
        [external_screen setCurrentMode:best];
        external_window = [[UIWindow alloc] init];
        external_window.screen = external_screen;
//        [external_window makeKeyAndVisible];
        external_window.hidden = NO;

        switch(fillmode) {
            case 0:
                [external_screen setOverscanCompensation:UIScreenOverscanCompensationInsetApplicationFrame];
                break;
            case 1:
                [external_screen setOverscanCompensation:UIScreenOverscanCompensationInsetBounds];
                break;
            case 2:
                [external_screen setOverscanCompensation:UIScreenOverscanCompensationScale]; break;
            case 3:
                break;
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    // start or restart movie player
    // http://stackoverflow.com/questions/4560065/MPMoviePlayerController-switching-movies-causes-white-flash
    /////////////////////////////////////////////////////////////////////////////////////////////

    if(!useavplayer) {
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
            //if(bounds.size.width < bounds.size.height) {
            //    float temp = bounds.size.width;
            //    bounds.size.width = bounds.size.height;
            //    bounds.size.height = temp;
            //}
            //view.transform = CGAffineTransformMakeRotation(M_PI_2);
            [moviePlayer.view setFrame:bounds];
            [self.view addSubview:moviePlayer.view];
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:moviePlayer];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerDidExitFullscreenNotification
                                                      object:moviePlayer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlaybackComplete:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlaybackComplete:)
                                                     name:MPMoviePlayerDidExitFullscreenNotification
                                                   object:nil];
        
        [moviePlayer setControlStyle:MPMovieControlStyleNone];
        moviePlayer.fullscreen = YES;
        moviePlayer.scalingMode = MPMovieScalingModeFill;
        moviePlayer.repeatMode = loopmode ? 1 : 0;
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
            
            AVPlayerLayer *avPlayerLayer = [[AVPlayerLayer playerLayerWithPlayer:player] retain];
            [avPlayerLayer setFrame:bounds];
        //    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            NSLog(@"avplayer bounds are %f,%f",bounds.size.width,bounds.size.height);

            UIView *newView = [[UIView alloc] initWithFrame:bounds];
            newView.backgroundColor = [UIColor blackColor];
            //[newView setContentStretch:CGRect(0,0,100,100)];
            [newView.layer addSublayer:avPlayerLayer];
            if(external_window) {
                [external_window addSubview:newView];
                // make a touchable area
                UIView *newView2 = [[UIView alloc] initWithFrame:bounds];
                newView2.backgroundColor = [UIColor yellowColor];
                //[newView setContentStretch:CGRect(0,0,100,100)];
                [self.view addSubview:newView2];
            } else {
                [self.view addSubview:newView];
            }


        } else {
            [player pause];
            AVAsset *asset = [AVURLAsset URLAssetWithURL:filepathurl options:nil];
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        }

        //playerLayer.needsDisplayOnBoundsChange = YES;
        //playbackView.layer.needsDisplayOnBoundsChange = YES;

        [player play];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[player currentItem]];
    

        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

        
        NSLog(@"playing a new movie %@",filepathurl);

        //[player pause];
        //[player replaceCurrentItemWithPlayerItem:newPlayerItem];

        // [asset load];

    }

}

/////////////////////////////////////////////////////////////////////////////////////////////
// startup
/////////////////////////////////////////////////////////////////////////////////////////////

- (void) resetTo:(float)time {
    if(moviePlayer) {
        [moviePlayer pause];
        [moviePlayer setCurrentPlaybackTime:time];
        nloops = 0;
    }

    if(player) {
        [player pause];
        Float64 seconds = time;
        int32_t preferredTimeScale = 25;
        CMTime inTime = CMTimeMakeWithSeconds(seconds, preferredTimeScale);
        [player seekToTime:inTime];
        nloops = 0;
    }
}

- (void) playmode:(int)state { // -1 = toggle, 0 = stop, 1 = play
    if(moviePlayer) {
        if(moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
            if(state == -1 || state == 0) {
                [moviePlayer pause];
                NSLog(@"Asked to toggle or pause a running movie - pausing movie");
            } else if(state == 1) {
                NSLog(@"Asked to play but already playing");
            }
        } else {
            // we are paused - circumvent loop end case
            if(!loopmode && nloops) {
                nloops = 0;
                [moviePlayer setCurrentPlaybackTime:0];
            }
            // if we want to play or toggle do so
            if(state == -1 || state == 1) {
                [moviePlayer pause];
                NSLog(@"Asked to toggle or play a paused movie - playing movie");
                [moviePlayer play];
            } else if(state == 0) {
                NSLog(@"Asked to stop but already stopped");
            }
        }
    }

    // variation of above - xxx could use a polymorphic base
    if(player) {
        if(player.rate != 0) {
            if(state == -1 || state == 0) {
                [player pause];
                NSLog(@"Asked to toggle or pause a running movie - pausing movie");
            } else if(state == 1) {
                NSLog(@"Asked to play but already playing");
            }
        } else {
            if(!loopmode && nloops) {
                nloops = 0;
                [player seekToTime:kCMTimeZero]; // if done then reset
            }
            // if we want to play or toggle do so
            if(state == -1 || state == 1) {
                [player pause];
                NSLog(@"Asked to toggle or play a paused movie - playing movie");
                [player play];
            } else if(state == 0) {
                NSLog(@"Asked to stop but already stopped");
            }
        }
    }
    
}

- (void) playNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"Play"]) {
        if(playme) {
            // play requested file
            [self playMovie:playme];
        }
    }
}

ServerBrowser* networkServerBrowser = 0;

- (void)networkTrafficReceived:(id)notification {
    if ([[notification name] isEqualToString:@"NetworkTrafficReceived"]) {
        NSLog(@"Network traffique");
        NSDictionary* dict = [notification userInfo];
        if(dict) {
            NSString* message = [dict objectForKey:@"message"];
            NSString* value = [dict objectForKey:@"value"];
            float val = 0;
            if(value && [value length] > 0) {
                val = [value floatValue];
            } else {
                value = 0;
            }
            if(message) {
                NSLog(@"Network Traffic Received %@",message);
                if([message isEqualToString:@"toggle"]) {
                    [self playmode:-1];
                }
                else if([message isEqualToString:@"pause"]) {
                    if(value) [self resetTo:val];
                    [self playmode:0];
                }
                else if([message isEqualToString:@"stop"]) {
                    if(value) [self resetTo:val];
                    [self playmode:0];
                }
                else if([message isEqualToString:@"play"]) {
                    if(value) [self resetTo:val];
                    [self playmode:1];
                }
                else if([message isEqualToString:@"reset"]) {
                    [self resetTo:val];
                }
                else if([message isEqualToString:@"goto"]) {
                    [self resetTo:val];
                }
                else if([message isEqualToString:@"launch"]) {
                    NSString* file = [dict objectForKey:@"value"];
                    if(file) {
                        playme = [self findFile:file];
                        if(file) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
                        }
                    }
                }
            }
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
    if(networkServerBrowser) {
        [networkServerBrowser stop];
        [networkServerBrowser release];
    }
    networkServerBrowser = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(serverurl && serverurl.length > 1) {
        // preferentially try to visit url to get commands to run
        [self pollNetwork:self];
    } else {
        if(defaultFile) {
            // try play that
            playme = [self findFile:defaultFile];
            if(playme) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
            }
        } else {
            // if no file supplied by network try play first file
            playme = [self findFile:0];
            if(playme) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
            }
        }
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];

    // start a small bonjour listener
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkServiceFound:) name:@"NetworkServiceFound" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTrafficReceived:) name:@"NetworkTrafficReceived" object:nil];
    networkServerBrowser = [[ServerBrowser alloc] init];
    [networkServerBrowser start];

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self playmode:-1]; // toggle
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}


@end


