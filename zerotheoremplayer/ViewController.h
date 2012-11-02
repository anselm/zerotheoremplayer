
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIGestureRecognizerDelegate>
-(id)initWithURL:(NSString*)url;
-(void)playMovie:(NSURL*) filepathurl;
@end

