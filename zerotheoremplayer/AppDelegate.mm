
#import "AppDelegate.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ListController.h"
#import "FilePicker.h"

@implementation AppDelegate

- (void)dealloc {
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(!useexternal) return true;
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    application.statusBarHidden = YES;
	application.statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    FilePicker* filepicker = [[FilePicker alloc] init];
    
	// And a navigation bar
	UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:filepicker];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    NSLog(@"starting bounds are %f,%f",bounds.size.width,bounds.size.height); // not valid till after viewwillappear
    
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    self.window.rootViewController = nav;
    //self.viewController = (UIViewController*)nav;
//    [self.window addSubview:control.view];
    [self.window makeKeyAndVisible];
    
    return YES;

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   // exit(0);
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
