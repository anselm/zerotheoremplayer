
#import "FilePicker.h"
#import "ViewController.h"
#import "ListController.h"

@implementation FilePicker

NSString* text = @"http://hook.org/l/files.json";

- (id) init {
	self = [super init]; // initWithStyle: UITableViewStyleGrouped ];
	if (self != nil) {
		self.title = @"Choose source";
	}
	return self;
}

-(void) local2Picked:(UIButton*)sender {
    
    if(activeTextField) {
        text = [[activeTextField text] copy];
    }
    
    ViewController* control = [[ViewController alloc] initWithURL:0];
    [self presentViewController:control animated:YES completion:NULL];
}

-(void) buttonPicked:(UIButton*)sender {
    
    if(activeTextField) {
        text = [[activeTextField text] copy];
    }
    
    if(text) {
        ViewController* control = [[ViewController alloc] initWithURL:text];
        [self presentViewController:control animated:YES completion:NULL];
    }
}

-(void) localPicked:(UIButton*)sender {
    
    if(activeTextField) {
        text = [[activeTextField text] copy];
    }
    
    ListController* control = [[ListController alloc] init];
    //[self presentViewController:control animated:YES completion:NULL];
    [[self navigationController] pushViewController:control animated:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    activeTextField = textField;
    text = [[textField text] copy];
    //NSLog(@"textFieldShouldBeginEditing: sender = %d, %@", [textField tag], [textField text]);
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    //NSLog(@"textFieldDidEndEditing: sender = %d, %@", [textField tag], [textField text]);
    text = [[textField text] copy];
	// test scrap
	//AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	//[app showGlobe];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //NSLog(@"textFieldShouldReturn: sender = %d, %@", [textField tag], [textField text]);
    text = [[textField text] copy];
    activeTextField = nil;
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(!useexternal) return true;
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}


- (void)switchAction:(UISwitch*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];
    //   NSLog(@"switchAction: sender = %d, isOn %d", [sender tag], [sender isOn]);
    
    useavplayer = [sender isOn] ? 1 : 0;
}

- (void)externAction:(UISwitch*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];
    //   NSLog(@"switchAction: sender = %d, isOn %d", [sender tag], [sender isOn]);
    
    useexternal = [sender isOn] ? 1 : 0;
}

- (void)segmentRotated:(UISegmentedControl*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];
    
    rotated = [sender selectedSegmentIndex];
    NSLog(@"set rotation %f",rotated);
    
    NSUserDefaults *c = [NSUserDefaults standardUserDefaults];
    [c setFloat:rotated forKey:@"rotation"]; // basically we blow away the rotated settings if you set it here xxx improve design here todo
    [c synchronize];

}

- (void)segmentInteractive:(UISegmentedControl*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];

    interactive = [sender selectedSegmentIndex] ? 0 : 1;
    
    
}


- (void)segmentAction:(UISegmentedControl*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];
    
    fillmode = [sender selectedSegmentIndex];
}

- (void)loopAction:(UISegmentedControl*)sender {
    if ([activeTextField canResignFirstResponder])
		[activeTextField resignFirstResponder];
    
    loopmode = [sender selectedSegmentIndex];
}


- (void)viewDidLoad {

    // http://stackoverflow.com/questions/11522672/getting-the-correct-bounds-of-uiviewcontrollers-view
    CGRect bounds = [[UIScreen mainScreen] bounds];
    NSLog(@"runtime bounds are %f,%f",bounds.size.width,bounds.size.height); // not valid till after viewwillappear

    
    ////////////////////////////////////////
    // movie mode; avplayer or not
    {
        UILabel* l = [[UILabel alloc] initWithFrame: CGRectMake(60,40*1,100,30)];
        [l setText:@"avplayer"];
        [self.view addSubview:l];
        
        UISwitch *e = [ [ UISwitch alloc ] initWithFrame: CGRectMake(160, 40*1,100, 30) ];
        e.on = useavplayer ? YES : NO;
        e.tag = 1;
        [e addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        //cell.text = @"Reset";
        [self.view addSubview: e ];
    }
    
    ////////////////////////////////////////
    // movie mode; use extern
    {
        UILabel* l = [[UILabel alloc] initWithFrame: CGRectMake(260,40*1,100,30)];
        [l setText:@"extern"];
        [self.view addSubview:l];
        
        UISwitch *e = [ [ UISwitch alloc ] initWithFrame: CGRectMake(360, 40*1,100, 30) ];
        e.on = useexternal ? YES : NO;
        e.tag = 1;
        [e addTarget:self action:@selector(externAction:) forControlEvents:UIControlEventValueChanged];
        //cell.text = @"Reset";
        [self.view addSubview: e ];
    }
    
    ////////////////////////////////////////
    // fill mode
    {
        UISegmentedControl *e = [ [ UISegmentedControl alloc ] initWithFrame:CGRectMake(60, 40*2,400, 30)  ];
        [ e insertSegmentWithTitle: @"Frame" atIndex: 0 animated: NO ];
        [ e insertSegmentWithTitle: @"Inset" atIndex: 1 animated: NO ];
        [ e insertSegmentWithTitle: @"Scale" atIndex: 2 animated: NO ];
        [ e insertSegmentWithTitle: @"None" atIndex: 3 animated: NO ];
        e.selectedSegmentIndex = fillmode;
        e.tag = 2;
        [e addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview: e ];
    }
    
    ////////////////////////////////////////
    // looping?
    {
        UISegmentedControl *e = [ [ UISegmentedControl alloc ] initWithFrame:CGRectMake(60, 40*3,400, 30)  ];
        [ e insertSegmentWithTitle: @"once" atIndex: 0 animated: NO ];
        [ e insertSegmentWithTitle: @"loop" atIndex: 1 animated: NO ];
        e.selectedSegmentIndex = loopmode;
        e.tag = 2;
        [e addTarget:self action:@selector(loopAction:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview: e ];
    }
    
    /////////////////////////////////////////
    // no network button
    
    {
        UIButton *e = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        e.frame = CGRectMake(60, 40*4, 400, 30);
        //[button setFrame: CGRectMake(120,10,100,10)];
        //button.backgroundColor = [UIColor blueColor];
        [e setTitle:@"Pick Files" forState:UIControlStateNormal];
        [e addTarget:self action:@selector(localPicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:e];
    }
    
    /////////////////////////////////////////
    // network input
/*
    UITextField *playerTextField = [ [ UITextField alloc ] initWithFrame: CGRectMake(60, 40*5, 400, 40) ];
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
    
    playerTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the r
    playerTextField.text = @"";
    [ playerTextField setEnabled: YES ];
    //[playerTextField release];
    
    //playerTextField.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [self.view addSubview:playerTextField];
*/
    
    ////////////////////////////////////////
    // rotate
    {
        UISegmentedControl *e = [ [ UISegmentedControl alloc ] initWithFrame:CGRectMake(60, 40*6,400, 30)  ];
        [ e insertSegmentWithTitle: @"rot0" atIndex: 0 animated: NO ];
        [ e insertSegmentWithTitle: @"rot1" atIndex: 1 animated: NO ];
        [ e insertSegmentWithTitle: @"rot2" atIndex: 2 animated: NO ];
        [ e insertSegmentWithTitle: @"rot3" atIndex: 3 animated: NO ];
        e.selectedSegmentIndex = rotated;
        e.tag = 9;
        [e addTarget:self action:@selector(segmentRotated:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview: e ];
    }

    ////////////////////////////////////////
    // interactive
    {
        UISegmentedControl *e = [ [ UISegmentedControl alloc ] initWithFrame:CGRectMake(60, 40*7,400, 30)  ];
        [ e insertSegmentWithTitle: @"touch" atIndex: 0 animated: NO ];
        [ e insertSegmentWithTitle: @"notouch" atIndex: 1 animated: NO ];
        e.selectedSegmentIndex = interactive ? 0 : 1;
        e.tag = 10;
        [e addTarget:self action:@selector(segmentInteractive:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview: e ];
    }

    ////////////////////////////////////////////
    // button
/*
    UIButton *button = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    button.frame = CGRectMake(60, 40*8, 400, 30);
    [button setTitle:@"Connect" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonPicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
  */  
    UILabel* l = [[UILabel alloc] initWithFrame: CGRectMake(60,40*9,100,30)];
    [l setText:@"v 2.6 norot"];
    [self.view addSubview:l];    
}

@end
