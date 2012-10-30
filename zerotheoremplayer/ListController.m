
#import "ListController.h"
#import "ViewController.h"

extern NSString* defaultFile;

@implementation ListController

NSArray *filelist = 0;

- (id) init {
	if(self = [super initWithStyle: UITableViewStylePlain]) {
		self.title = @"Files";
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		self.tableView.rowHeight = 48.0;
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.tableView.sectionHeaderHeight = 0;
	}

    // get the files here
    NSArray* dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docsDir = [dirPaths objectAtIndex:0];
    NSFileManager *filemgr =[NSFileManager defaultManager];
    if ([filemgr changeCurrentDirectoryPath: docsDir] == YES) {
        filelist = [[filemgr contentsOfDirectoryAtPath:docsDir error:NULL] retain];
    }

	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filelist ? [filelist count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ImageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

	NSString *title = [filelist objectAtIndex:indexPath.row];
	cell.textLabel.text = title;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *title = [filelist objectAtIndex:indexPath.row];
    defaultFile = title;
    ViewController* control = [[ViewController alloc] initWithURL:0];
    [self presentViewController:control animated:YES completion:NULL];
}

@end
