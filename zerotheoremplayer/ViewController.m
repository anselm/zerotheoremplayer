
#import "ViewController.h"
#import "ServerBrowser.h"
#import "Connection.h"

/////////////////////////////////////////////////////////////////////////////////////////////
// shared globals
/////////////////////////////////////////////////////////////////////////////////////////////

bool useexternal = 1;
bool useavplayer = 1;
int fillmode = 2;
int loopmode = 1;
int rotated = 0;
NSString* defaultFile = 0;
int nloops = 0;
int skipBlack = 1;
float worldx = 0;
float worldy = 0;
float stretchx = 1.0;
float stretchy = 1.0;
float rotation = 0.0f;

/////////////////////////////////////////////////////////////////////////////////////////////
// av player util
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

@synthesize networkServerBrowser, nameLabel;

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
// http network scanner ( slightly obsolete now that i use bonjour to directly connect)
/////////////////////////////////////////////////////////////////////////////////////////////

static NSString* serverurl = 0;
static NSURL* playme = 0;
static NSURLRequest* request;
static NSURLConnection* connection;
static NSMutableData* responseData = nil;
static NSString* lastcommand = 0;
static int poll_count = 0;

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
// mp player
// http://stackoverflow.com/questions/4560065/MPMoviePlayerController-switching-movies-causes-white-flash
/////////////////////////////////////////////////////////////////////////////////////////////

- (void) setupMoviePlayer:(NSURL*)filepathurl {

    // remove old listeners if any

    if(moviePlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:moviePlayer];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerDidExitFullscreenNotification
                                                      object:moviePlayer]; // xxx why is this object moviePlayer
    }
    
    // kill old - no point in doing this later
    
    MPMoviePlayerController* old = moviePlayer;
    
    if(old) {
        //old.scalingMode = MPMovieScalingModeNone;
        //[old setFullscreen:NO];
        [old.view removeFromSuperview];
        [old stop];
        [old release];
    }
    
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:filepathurl];

    // attach to appropriate window
    
    if(external_window) {
        [external_window addSubview:moviePlayer.view];
    } else {
        CGRect bounds = [[UIScreen mainScreen] bounds];
        if(bounds.size.width < bounds.size.height) {
            float temp = bounds.size.width;
            bounds.size.width = bounds.size.height;
            bounds.size.height = temp;
            NSLog(@"had to flip view"); // xxx resolve annoying ipad issue todo
        }
        [moviePlayer.view setFrame:bounds];
        [self.view addSubview:moviePlayer.view];
    }

    // re add listeners
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlaybackComplete:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlaybackComplete:)
                                                 name:MPMoviePlayerDidExitFullscreenNotification
                                               object:nil];
    
    //////////////////////////////////////////////////////////////////////
    // play
    //////////////////////////////////////////////////////////////////////
    
    [moviePlayer setControlStyle:MPMovieControlStyleNone];
    moviePlayer.fullscreen = YES;
    moviePlayer.scalingMode = MPMovieScalingModeFill;
    moviePlayer.repeatMode = loopmode ? 1 : 0;
    [moviePlayer play];
    NSLog(@"playing a new movie %@",filepathurl);
    
    // set this globally
    
    localview = self.view; // xxx shouldn't this be the movieview? then we could generalize scalex and the like also
}


- (void)moviePlaybackComplete:(NSNotification *)notification {
    nloops++;
    if(moviePlayer) {

        if(skipBlack) {
            // this disables not-looping - a way to re-loop because the end of some movies is not black
            [moviePlayer setCurrentPlaybackTime:2];
            [moviePlayer play];
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

/////////////////////////////////////////////////////////////////////////////////////////////
// avplayer
/////////////////////////////////////////////////////////////////////////////////////////////

- (void) setupAVPlayer:(NSURL*)filepathurl {
    
    if(!player) {
        
        // get the assets
        AVAsset *asset = [AVURLAsset URLAssetWithURL:filepathurl options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        player = [[AVPlayer playerWithPlayerItem:playerItem] retain];
        duration = player.currentItem.asset.duration;
        
        // get bounds of target
        CGRect bounds = [self.view bounds];
        if(external_window) {
            bounds = [external_window bounds];
        } else {
            if(bounds.size.width < bounds.size.height) {
                float temp = bounds.size.width;
                bounds.size.width = bounds.size.height;
                bounds.size.height = temp;
                NSLog(@"had to flip view"); // xxx resolve annoying ipad issue todo
            }
        }
        // turns out 0,0 is fine
        //worldx = bounds.size.width / 2;
        //worldy = bounds.size.height / 2;

        
        // make av player
        AVPlayerLayer *avPlayerLayer = [[AVPlayerLayer playerLayerWithPlayer:player] retain];
        [avPlayerLayer setFrame:bounds];
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // this is the key line to fill display edge to edge
        NSLog(@"avplayer bounds are %f,%f",bounds.size.width,bounds.size.height);
        
        // always make a local view
        localview = [[UIView alloc] initWithFrame:bounds];
        localview.backgroundColor = [UIColor blackColor];
        [self.view addSubview:localview];
        
        // decide where to attach av player
        if(external_window) {
            externalview = [[UIView alloc] initWithFrame:bounds];
            externalview.backgroundColor = [UIColor blackColor];
            [externalview.layer addSublayer:avPlayerLayer];
            [external_window addSubview:externalview];
        } else {
            localview.backgroundColor = [UIColor blackColor];
            [localview.layer addSublayer:avPlayerLayer];
        }

    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // just load something new into the player
    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    else {
        [player pause];
        AVAsset *asset = [AVURLAsset URLAssetWithURL:filepathurl options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [player replaceCurrentItemWithPlayerItem:playerItem];
        //[player seekToTime:kCMTimeZero];
    }
    
    // play it
    
    //playerLayer.needsDisplayOnBoundsChange = YES;
    //playbackView.layer.needsDisplayOnBoundsChange = YES;
    
    [player play];
    
    // do this more than once??? XXX todo
    
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


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if(player) {
        nloops++;
        if(skipBlack || loopmode) {
            // this disables not-looping - a way to re-loop because the end of some movies is not black
            Float64 seconds = 0;
            int32_t preferredTimeScale = 25;
            CMTime inTime = CMTimeMakeWithSeconds(seconds, preferredTimeScale);
            [player seekToTime:inTime];
          //  [player play];
            nloops = 0;
        }
    }
}

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
// shared
/////////////////////////////////////////////////////////////////////////////////////////////

-(void)playMovie:(NSURL*) filepathurl {

    if(!filepathurl)return;
    
    // remove gesture recognizers?

    if(pinchRecognizer && localview) {
        [localview removeGestureRecognizer:pinchRecognizer];
    }
    if(panRecognizer && localview) {
        [localview addGestureRecognizer:panRecognizer];        
    }
    if(panRecognizer && localview) {
        [localview removeGestureRecognizer:panRecognizer];
    }
    if(tapRecognizer && localview) {
        [localview removeGestureRecognizer:tapRecognizer];
    }
    if(rotationRecognizer && localview) {
        [localview removeGestureRecognizer:rotationRecognizer];
    }

    // setup external?

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
        // [external_window makeKeyAndVisible];
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

    // play the video

    if(!useavplayer) {
        [self setupMoviePlayer:filepathurl];
    } else {
        [self setupAVPlayer:filepathurl];
    }

    // re attach gesture recognizers
    
    if(!pinchRecognizer) {
        pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onscale:)];
        [pinchRecognizer setDelegate:self];
    }
    [localview addGestureRecognizer:pinchRecognizer];

    if(!rotationRecognizer) {
        rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(onrotate:)];
        [rotationRecognizer setDelegate:self];
    }
    [localview addGestureRecognizer:rotationRecognizer];
    
    if(!panRecognizer) {
        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onmove:)];
        [panRecognizer setMinimumNumberOfTouches:1];
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelegate:self];
    }
    [localview addGestureRecognizer:panRecognizer];

    if(!tapRecognizer) {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ontapped:)];
        [tapRecognizer setNumberOfTapsRequired:1];
        [tapRecognizer setDelegate:self];
    }
    [localview addGestureRecognizer:tapRecognizer];

}

- (void) visible:(int) status {
    if(moviePlayer && moviePlayer.view) moviePlayer.view.alpha = status ? 1 : 0;
    if(localview) localview.alpha = status ? 1 : 0;
}

- (void) resetTo:(float)time {
    
    NSLog(@"attempting to jump player to time %f",time);

    if(moviePlayer) {
        [moviePlayer pause];
        [moviePlayer setCurrentPlaybackTime:time];
        nloops = 0;
    }
    
    if(player) {
        [player pause];
        Float64 seconds = time;
        int32_t preferredTimeScale = 1;
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
    } else {
        NSLog(@"got a request to play nothing");
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// event request handling
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static float lastScaleX = 1.0;
static float lastScaleY = 1.0;
static float lastRotation = 0.0;
static float firstX = 0.0, firstY = 0.0;
static CGAffineTransform transform;

-(void)configSave {
    NSUserDefaults *c = [NSUserDefaults standardUserDefaults];
    [c setObject:@"v11" forKey:@"v"];
    [c setFloat:lastScaleX forKey:@"lastScaleX"];
    [c setFloat:lastScaleY forKey:@"lastScaleY"];
    [c setFloat:worldx forKey:@"worldx"];
    [c setFloat:worldy forKey:@"worldy"];
    [c setFloat:rotation forKey:@"rotation"];
    [c synchronize];
}

-(void)configLoad {
    NSUserDefaults *c = [NSUserDefaults standardUserDefaults];
    [c synchronize];
    if([[c stringForKey:@"v"] isEqualToString:@"v11"]) {
        lastScaleX = [c floatForKey:@"lastScaleX"];
        lastScaleY = [c floatForKey:@"lastScaleX"];
        worldx = [c floatForKey:@"worldx"];
        worldy = [c floatForKey:@"worldy"];
        rotation = [c floatForKey:@"rotation"];
        [self scale:0 y:0];
        [self move:0 y:0];
    }
}

-(void)configApply {
    NSLog(@"view stretch %f %f move %f %f rotation %f",stretchx,stretchy,worldx,worldy,rotation);
    UIView* view = externalview ? externalview : localview;
    if(!view)return;
    transform = CGAffineTransformTranslate(CGAffineTransformIdentity,worldx,worldy);
    transform = CGAffineTransformScale(transform,stretchx,stretchy);
    transform = CGAffineTransformRotate(transform,rotation* M_PI/2.0);
    [view setTransform:transform];
    [self configSave];
}

-(void)configReset {
    lastScaleX = lastScaleY = 1.0;
    worldx = worldy = 0;
    rotation = 0;
    [self configApply];
}

-(void)rotate:(float)r {
    rotation += r;
    [self configApply];
}

-(void)scale:(float)x y:(float)y {
    stretchx += x;
    stretchy += y;
    [self configApply];
}

-(void)move:(float)x y:(float)y {
    worldx += x;
    worldy += y;
    [self configApply];
}

-(void)onscale:(id)sender {
    // http://www.icodeblog.com/2010/10/14/working-with-uigesturerecognizers/

    UIView* view = externalview ? externalview : localview;
    if(!view)return;

	if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
		lastScaleX = stretchx;
		lastScaleY = stretchy;
	}

	CGFloat scale = [(UIPinchGestureRecognizer*)sender scale] - 1.0;

    stretchx = lastScaleX + scale;
    stretchy = lastScaleY + scale;

    [self configApply];
}

-(void)onrotate:(id)sender {

    // disabled xxx and broken
    if(1)return;
    UIView* view = externalview ? externalview : localview;
    if(!view)return;
    
	if([(UIRotationGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        lastRotation = 0.0;
		return;
	}
	//CGFloat rotation = 0.0 - (lastRotation - [(UIRotationGestureRecognizer*)sender rotation]);
	//lastRotation = [(UIRotationGestureRecognizer*)sender rotation];

    [self configApply];
}

-(void)onmove:(id)sender {

    UIView* view = externalview ? externalview : localview;
    if(!view)return;

	[[view layer] removeAllAnimations];
    
	if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
		firstX = worldx;
		firstY = worldy;
	}

    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:view];
    /*
    if(!external_screen) {
        translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY+translatedPoint.y);
    }
    else if(external_screen) {
        translatedPoint = CGPointMake(firstX+translatedPoint.y, firstY-translatedPoint.x);
       // translatedPoint = CGPointMake(firstX-translatedPoint.y, firstY+translatedPoint.x);
    }
     
     //	[view setCenter:translatedPoint];
     */

    worldx = translatedPoint.x+firstX;
    worldy = translatedPoint.y+firstY;

    [self configApply];

    
    /* animated interpolator - stupid
	if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
		CGFloat finalX = translatedPoint.x + (.35*[(UIPanGestureRecognizer*)sender velocityInView:view].y);
		CGFloat finalY = translatedPoint.y - (.35*[(UIPanGestureRecognizer*)sender velocityInView:view].x);
        
		//if(UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
			if(finalX < 0) finalX = 0; else if(finalX > 768) finalX = 768;
			if(finalY < 0) finalY = 0; else if(finalY > 1024) finalY = 1024;
		///}

		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:.35];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[view setCenter:CGPointMake(finalX, finalY)];
		[UIView commitAnimations];
	}*/
}

-(void)ontapped:(id)sender {
	NSLog(@"See a tap gesture");
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self playmode:-1]; // toggle
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// network
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) hideHealth:(NSTimer*)timer {
    if(nameLabel) {
        [nameLabel removeFromSuperview];
    }
}

- (void)showHealth {
    UIView* view = externalview ? externalview : localview;
    if(!view)return;
    if(!nameLabel) {
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,200, 800, 70)];
        [nameLabel setTextColor:[UIColor greenColor]];
        [nameLabel setBackgroundColor:[UIColor redColor]];
        [nameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 64.0f]];
    }
    if(networkServerBrowser) {
        NSString* blah = [NSString stringWithFormat:@"%@ %@ %@",
                          [networkServerBrowser device_name],
                          [networkServerBrowser device_power],
                          [networkServerBrowser device_state]
                          ];
        [nameLabel setText:blah];
    }
    [nameLabel removeFromSuperview];
    if(externalview) {
        [externalview addSubview:nameLabel];
    } else if(localview) {
        [localview addSubview:nameLabel];
    }
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideHealth:) userInfo:nil repeats:NO];
}

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
                else if([message isEqualToString:@"hide"]) {
                    [self visible:0];
                }
                else if([message isEqualToString:@"show"]) {
                    [self visible:1];
                }
                else if([message isEqualToString:@"goto"]) {
                    [self resetTo:val];
                }
                else if([message isEqualToString:@"movex"]) {
                    [self move:val y:0];
                }
                else if([message isEqualToString:@"movey"]) {
                    [self move:0 y:val];
                }
                else if([message isEqualToString:@"reset"]) {
                    [self configReset];
                }
                else if([message isEqualToString:@"stretchx"]) {
                    [self scale:val y:0];
                }
                else if([message isEqualToString:@"stretchy"]) {
                    [self scale:0 y:val];
                }
                else if([message isEqualToString:@"stretchy"]) {
                    [self scale:0 y:val];
                }
                else if([message isEqualToString:@"rotate"]) {
                    [self rotate:val];
                }
                else if([message isEqualToString:@"health"]) {
                    [self showHealth];
                }
                else if([message isEqualToString:@"launch"]) {
                    NSString* file = [dict objectForKey:@"value"];
                    if(file) {
                        playme = [self findFile:file];
                        NSLog(@"got a request to launch %@ with status %@",file, ( playme ? @"found it" : @"did not find it"));
                        if(playme) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"Play" object:self];
                            //[self resetTo:0];
                            //[self visible:1];
                        }
                    }
                }
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:false];
    [self showHealth];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // fetch an url for commands?

    if(serverurl && serverurl.length > 1) {
        // preferentially try to visit url to get commands to run
        [self pollNetwork:self];
    }
    
    // or play a local file or first file
    
    else {
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

    // listen to network

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkServiceFound:) name:@"NetworkServiceFound" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTrafficReceived:) name:@"NetworkTrafficReceived" object:nil];
    networkServerBrowser = [[ServerBrowser alloc] init];
    [networkServerBrowser retain];
    [networkServerBrowser start];

    // load configs

    [self configLoad];

}


@end


