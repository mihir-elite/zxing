//
//  ZXMainViewController.m
//  Barcodes
//
//  Created by Romain Pechayre on 11/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ZXMainViewController.h"
#import <QRCodeReader.h>
#import <UniversalResultParser.h>
#import <ParsedResult.h>
#import <ResultAction.h>

@implementation ZXMainViewController
@synthesize resultParser;
@synthesize actions;
@synthesize result;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}
*/

      
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
 UniversalResultParser *parser = [[UniversalResultParser alloc] initWithDefaultParsers];
 self.resultParser = parser;
 [parser release];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (IBAction)scan:(id)sender {
	
  ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];
  QRCodeReader* qrcodeReader = [[QRCodeReader alloc] init];
  NSSet *readers = [[NSSet alloc ] initWithObjects:qrcodeReader,nil];
  [qrcodeReader release];
  widController.readers = readers;
  [readers release];
  NSBundle *mainBundle = [NSBundle mainBundle];
  widController.soundToPlay =
  [NSURL fileURLWithPath:[mainBundle pathForResource:@"beep-beep" ofType:@"aiff"] isDirectory:NO];
  [self presentModalViewController:widController animated:YES];
  [widController release];
}

- (void) messageReady:(id)sender {
  MessageViewController *messageController = sender;
  [self presentModalViewController:messageController animated:YES];
  [messageController release];
}

- (void) messageFailed:(id)sender {
  MessageViewController *messageController = sender;
  NSLog(@"Failed to load message!");
  [messageController release];
}

- (IBAction)info:(id)sender {
  MessageViewController *aboutController =
  [[MessageViewController alloc] initWithMessageFilename:@"About"
                                                 /* target:self
                                               onSuccess:@selector(messageReady:)
                                               onFailure:@selector(messageFailed:)*/];
  aboutController.delegate = self;
  [self presentModalViewController:aboutController animated:YES];
  [aboutController release];
}

- (void)messageViewControllerWantsToBeDispissed:(MessageViewController *)controller {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [resultParser release];
  actions = nil;
  result = nil;
  [super dealloc];
}

#pragma mark -
#pragma mark ZXingDelegateMethods

- (void)zxingController:(ZXingWidgetController*)controller didScanResult:(NSString *)resultString {
  [self dismissModalViewControllerAnimated:YES];
  ParsedResult *theResult = [self.resultParser resultForString:resultString];
  self.result = [theResult retain];
  self.actions = [self.result.actions retain];
#ifdef DEBUG
  NSLog(@"result has %d actions", actions ? 0 : actions.count);
#endif
  [self performResultAction];
}

- (void)confirmAndPerformAction:(ResultAction *)action {
  [action performActionWithController:self shouldConfirm:YES];
}

- (void)performResultAction {
  if (self.result == nil) {
    NSLog(@"no result to perform an action on!");
    return;
  }
  
  if (self.actions == nil || self.actions.count == 0) {
    NSLog(@"result has no actions to perform!");
    return;
  }
  
  if (self.actions.count == 1) {
    ResultAction *action = [self.actions lastObject];
#ifdef DEBUG
    NSLog(@"Result has the single action, (%@)  '%@', performing it",
          NSStringFromClass([action class]), [action title]);
#endif
    [self performSelector:@selector(confirmAndPerformAction:)
               withObject:action
               afterDelay:0.0];
  } else {
#ifdef DEBUG
    NSLog(@"Result has multiple actions, popping up an action sheet");
#endif
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithFrame:self.view.bounds];
    
    for (ResultAction *action in self.actions) {
      [actionSheet addButtonWithTitle:[action title]];
    }
    
    int cancelIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"DecoderViewController cancel button title", @"Cancel")];
    actionSheet.cancelButtonIndex = cancelIndex;
    
    actionSheet.delegate = self;
    
    [actionSheet showInView:self.view];
  }
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller {
  [self dismissModalViewControllerAnimated:YES];
}


@end
