//
//  ViewController.m
//  Produce-AR
//
//  Created by Ankush Gola on 10/6/17.
//  Copyright © 2017 Ankush Gola. All rights reserved.
//

#import "BluetoothManager.h"
#import "SoundManager.h"
#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate, BlueToothManagerDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end

    
@implementation ViewController
{
    // Manager for bluetooth io
    BluetoothManager *_bluetoothManager;
    
    // Manager for soundclips
    SoundManager *_soundManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    // Initialize SoundManager
    _soundManager = [[SoundManager alloc] initWithDefaults];
    
    // TEMPORARY: create buttons to test sounds
    UIButton *button1;
    button1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button1.frame = CGRectMake(30, 30, 60, 60);
    [button1 setTitle:@"Kick"
             forState:(UIControlState)UIControlStateNormal];
    [button1 setBackgroundColor:[UIColor blueColor]];
    [button1 addTarget:self
                action:@selector(playSound1:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [self.view addSubview:button1];
    
    UIButton *button2;
    button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.frame = CGRectMake(90, 90, 60, 60);
    [button2 setTitle:@"Snare"
             forState:(UIControlState)UIControlStateNormal];
    [button2 setBackgroundColor:[UIColor blueColor]];
    [button2 addTarget:self
                action:@selector(playSound2:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [self.view addSubview:button2];
    
    UIButton *button3;
    button3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button3.frame = CGRectMake(30, 90, 60, 60);
    [button3 setTitle:@"Hat"
             forState:(UIControlState)UIControlStateNormal];
    [button3 setBackgroundColor:[UIColor blueColor]];
    [button3 addTarget:self
                action:@selector(playSound3:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [self.view addSubview:button3];
    
    
    NSString *UUID = @"19B10010-E8F2-537E-4F6C-D104768A1214";
    _bluetoothManager = [[BluetoothManager alloc] initWithServiceUUID:UUID
                                             bluetoothManagerDelegate:self
                                                                queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

-(void) playSound1:(id)sender {
    [_soundManager playSound:kKickKey];
}

-(void) playSound2:(id)sender {
    [_soundManager playSound:kSnareKey];
}

-(void) playSound3:(id)sender {
    [_soundManager playSound:kHatKey];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

#pragma mark - BluetoothManagerDelegate

- (void)didReceiveValueFromBluetoothPeripheral:(NSData *)value
{
    NSString *strData = [[NSString alloc]initWithData:value encoding:NSUTF8StringEncoding];
    NSLog(@"recv: %@", strData);
    
    uint8_t theData = 'a';
    NSData *data = [NSData dataWithBytes:&theData length:1];
    [_bluetoothManager writeValue:data];
}

@end
