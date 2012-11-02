
#import <Foundation/Foundation.h>

@interface FilePicker: UIViewController<UITextFieldDelegate> {
    UITextField *activeTextField;
}
- (id) init;
@end
