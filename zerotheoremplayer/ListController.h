#import <UIKit/UIKit.h>
@interface ListController: UITableViewController <UITextFieldDelegate> {
}
- (id) init;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end