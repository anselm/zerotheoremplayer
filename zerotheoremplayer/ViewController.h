
#import <UIKit/UIKit.h>
#import "ServerBrowser.h"
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <UIGestureRecognizerDelegate> {
    ServerBrowser* networkServerBrowser;
    UILabel* nameLabel;
    
    UIScreen* external_screen;
    UIWindow* external_window;
    UIView* externalview;
    UIView* localview;

    MPMoviePlayerController *moviePlayer;

    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    CMTime duration;

    
    UIPinchGestureRecognizer* pinchRecognizer;
    UIRotationGestureRecognizer* rotationRecognizer;
    UIPanGestureRecognizer* panRecognizer;
    UITapGestureRecognizer* tapRecognizer;

}
@property(nonatomic,retain) ServerBrowser* networkServerBrowser;
@property(nonatomic,retain) UILabel* nameLabel;
-(id)initWithURL:(NSString*)url;
-(void)playMovie:(NSURL*) filepathurl;
@end

extern bool useexternal;
extern bool useavplayer;
extern int fillmode;
extern int loopmode;
extern int rotated;
