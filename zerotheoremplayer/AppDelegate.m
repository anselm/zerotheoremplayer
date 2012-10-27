
#import "AppDelegate.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface FilePicker: UIViewController<UITextFieldDelegate> {
UITextField *activeTextField;
}
- (id) init;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation FilePicker

NSString* text = @"http://hook.org/l/files.json";

- (id) init {
	self = [super init]; // initWithStyle: UITableViewStyleGrouped ];
	if (self != nil) {
		self.title = @"Choose source";
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case(0):
			return 2;
			break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
		case(0):
			return @"Enter URL";
			break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [ NSString stringWithFormat: @"%d:%d", [ indexPath indexAtPosition: 0 ], [ indexPath indexAtPosition:1 ]];
    
    UITableViewCell *cell = [ tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
		switch ([ indexPath indexAtPosition: 0]) {
			case(0):
				switch([ indexPath indexAtPosition: 1]) {
/*					case(2):
					{
						UISlider *musicVolumeControl = [ [ UISlider alloc ] initWithFrame: CGRectMake(170, 0, 125, 50) ];
						musicVolumeControl.minimumValue = 0.0;
						musicVolumeControl.maximumValue = 10.0;
						musicVolumeControl.tag = 0;
						musicVolumeControl.value = 3.5;
						musicVolumeControl.continuous = YES;
						[musicVolumeControl addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
						[ cell addSubview: musicVolumeControl ];
						//cell.text = @"Music Volume";
						[cell.textLabel setText:@"Music Volume"];
						[ musicVolumeControl release ];
					}
 */
						break;
					case(0):
					{
						UITextField *playerTextField = [ [ UITextField alloc ] initWithFrame: CGRectMake(150, 10, 145, 28) ];
						playerTextField.adjustsFontSizeToFitWidth = YES;
						playerTextField.textColor = [UIColor blackColor];
						playerTextField.font = [UIFont systemFontOfSize:18.0];
						playerTextField.placeholder = text;
						playerTextField.backgroundColor = [UIColor whiteColor];
						playerTextField.borderStyle = UITextBorderStyleLine;
						playerTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
						playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
						playerTextField.textAlignment = UITextAlignmentRight;
						playerTextField.keyboardType = UIKeyboardTypeDefault; // use the default type input method (entire keyboard)
						playerTextField.returnKeyType = UIReturnKeyDone;
						playerTextField.tag = 0;
						playerTextField.delegate = self;
                        
						playerTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
						playerTextField.text = @"";
						[ playerTextField setEnabled: YES ];
						[ cell addSubview: playerTextField ];
						//cell.text = @"Player";
						[cell.textLabel setText:@"Player"];
						//[playerTextField release];
                        activeTextField = playerTextField;
					}
                    break;
                    case(1):
                    {
                        
						UIButton *button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
						button.frame = CGRectMake(60, 6, 200, 35);
						//[button setFrame: CGRectMake(120,10,100,10)];
						//button.backgroundColor = [UIColor blueColor];
						[button setTitle:@"Connect" forState:UIControlStateNormal];
						[button addTarget:self action:@selector(buttonPicked:) forControlEvents:UIControlEventTouchUpInside];
                        
						//button.center = self.center;
						//[cell.textLabel setText:@"Role"];
                        
						//[button setCenter:CGPointMake(120, 10)];
                        
						//	[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
						//	[button setTitleColor:[UIColor blackColor] forState:UIControlEventTouchDown];
						//	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
						//	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                        
						//UIView *transparentBackground = [[UIView alloc] initWithFrame:CGRectZero];
						//transparentBackground.backgroundColor = [UIColor clearColor];
						//cell.backgroundView = transparentBackground;
						//cell.contentView.backgroundColor = [UIColor blueColor];
                        
						[cell addSubview:button ];
						[button release];
						break;
                    }
                }
        }
    }
    return cell;
}

-(void) buttonPicked:(UIButton*)sender {

    if(activeTextField) {
        text = [[activeTextField text] copy];
    }

    if(text) {
        ViewController* control = [[ViewController alloc] initWithURL:text];
        [self presentViewController:control animated:YES completion:NULL];
        //[self presentModalViewController:control animated:true];
        //[[self parentViewController] addChildViewController:control];
        //[self removeFromParentViewController];
        //[self.navigationController setNavigationBarHidden:YES];
		//[self.navigationController pushViewController:control animated:true];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    activeTextField = textField;
    text = [[textField text] copy];
    NSLog(@"textFieldShouldBeginEditing: sender = %d, %@", [textField tag], [textField text]);
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"textFieldDidEndEditing: sender = %d, %@", [textField tag], [textField text]);
    text = [[textField text] copy];
	// test scrap
	//AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	//[app showGlobe];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"textFieldShouldReturn: sender = %d, %@", [textField tag], [textField text]);
    text = [[textField text] copy];
    activeTextField = nil;
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)viewDidLoad {
    UITextField *playerTextField = [ [ UITextField alloc ] initWithFrame: CGRectMake(60, 40, 400, 40) ];
    playerTextField.adjustsFontSizeToFitWidth = YES;
    playerTextField.textColor = [UIColor blackColor];
    playerTextField.font = [UIFont systemFontOfSize:28.0];
    playerTextField.placeholder = text;
    playerTextField.backgroundColor = [UIColor whiteColor];
    playerTextField.borderStyle = UITextBorderStyleLine;
    playerTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
    playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
    //playerTextField.textAlignment = UITextAlignmentLeft;
    playerTextField.keyboardType = UIKeyboardTypeDefault; // use the default type input method (entire keyboard)
    playerTextField.returnKeyType = UIReturnKeyDone;
    playerTextField.tag = 0;
    playerTextField.delegate = self;
    
    playerTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
    playerTextField.text = @"";
    [ playerTextField setEnabled: YES ];
    //[playerTextField release];

    //playerTextField.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [self.view addSubview:playerTextField];

    
    UIButton *button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    button.frame = CGRectMake(60, 100, 200, 40);
    //[button setFrame: CGRectMake(120,10,100,10)];
    //button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"Connect" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonPicked:) forControlEvents:UIControlEventTouchUpInside];
    
    //button.center = self.center;
    //[cell.textLabel setText:@"Role"];
    
    //[button setCenter:CGPointMake(120, 10)];
    
    //	[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    //	[button setTitleColor:[UIColor blackColor] forState:UIControlEventTouchDown];
    //	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    //	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    //UIView *transparentBackground = [[UIView alloc] initWithFrame:CGRectZero];
    //transparentBackground.backgroundColor = [UIColor clearColor];
    [self.view addSubview:button];

}

@end

@implementation AppDelegate

FilePicker* filepicker;

- (void)dealloc {
    [filepicker release];
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    application.statusBarHidden = YES;
	application.statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    
	// Start off with a profiles picker
	filepicker = [[FilePicker alloc] init];
    
	// And a navigation bar
	//UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:control];

    //self.viewController = (UIViewController*)nav;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    NSLog(@"bounds are %f,%f",bounds.size.width,bounds.size.height);
    
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    self.window.rootViewController = filepicker;
//    [self.window addSubview:control.view];
    [self.window makeKeyAndVisible];

    return YES;

}


@end
