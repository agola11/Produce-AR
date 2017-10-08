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

// Bluetooth UUID
static NSString *const UUID = @"19B10010-E8F2-537E-4F6C-D104768A1214";

// Geometric Constants (in meters)
static float const kPLANE_WIDTH = 2.0;
static float const kPLANE_HEIGHT = 1.0;

static float const kPLANE_X = 0.0;
static float const kPLANE_Y = -0.5;
static float const kPLANE_Z = -2;

static float const kORTH_PLANE_HEIGHT = 0.5;

static NSUInteger const kNumMeasures = 8;
static NSUInteger const kAnimateQuantize = 128;

@interface ViewController () <ARSCNViewDelegate, BlueToothManagerDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (atomic) BOOL isAnimating;

@end

@interface SCNNodeWrapper : NSObject

@property SCNNode *node;
@property NSString *soundKey;

@end

@implementation SCNNodeWrapper
@end

    
@implementation ViewController
{
    BluetoothManager *_bluetoothManager; // manages Bluetooth I/O
    SoundManager *_soundManager; // manages sound
    SCNNode *_orthoPlaneNode; // panning plane
    NSMutableSet *_addedWaves; // waves added by bluetooth
    NSLock *_arrayLock; // locks the _addedWaves array
    NSMutableArray<SCNNodeWrapper*> *_nodesInArrangement; // holds references to all nodes in arrangement
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Container to hold all of the 3D geometry
    SCNScene *scene = [SCNScene new];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    // Set up initial plane
    [self setupGrid];
    // Set up orthogonal panning pane
    [self setUpOrthoMovingPlane];
    
    // Initialize lock, waves array
    _addedWaves = [NSMutableSet new];
    _arrayLock = [NSLock new];
    _nodesInArrangement = [NSMutableArray new];
    
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
    
    UIButton *button4;
    button4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button4.frame = CGRectMake(90, 30, 60, 60);
    [button4 setTitle:@"Playback"
             forState:(UIControlState)UIControlStateNormal];
    [button4 setBackgroundColor:[UIColor blueColor]];
    [button4 addTarget:self
                action:@selector(playBack:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [self.view addSubview:button4];
    
    // Initiliaze BluetoothManager
    _bluetoothManager = [[BluetoothManager alloc] initWithServiceUUID:UUID
                                             bluetoothManagerDelegate:self
                                                                queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

-(void) playSound1:(id)sender {
    [_soundManager playSound:kKickKey];
    [self startPanningArrangement:90];
}

-(void) playSound2:(id)sender {
    [_soundManager playSound:kSnareKey];
    [_arrayLock lock];
    [_addedWaves addObject:@(1)];
    [_arrayLock unlock];
}

-(void) playSound3:(id)sender {
    [_soundManager playSound:kHatKey];
}

-(void) playBack:(id)sender {
    [self startPanningPlayback:90];
}

-(void) startPanningPlayback:(float)bpm
{
    float bps = bpm / 60.0; // beats per second
    float totalPanningDuration = (float)kNumMeasures / bps;
    const float loopPanningDuration = totalPanningDuration / (float)kAnimateQuantize;
    
    const float constY = _orthoPlaneNode.position.y;
    const float constZ = _orthoPlaneNode.position.z;
    
    _isAnimating = YES;
    SCNAction *pan = [SCNAction moveByX:kPLANE_WIDTH y:0 z:0 duration:totalPanningDuration];
    [_orthoPlaneNode runAction:pan completionHandler:^{
        _isAnimating = NO;
        _orthoPlaneNode.position = SCNVector3Make(0.0-kPLANE_WIDTH/2, constY, constZ);
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^void () {
        NSMutableSet *arrangementCopy = [NSMutableSet setWithArray:_nodesInArrangement];
        float timeSinceAnimation = 0.0;
        while (_isAnimating) {
            float currentX = _orthoPlaneNode.position.x;
            for (SCNNodeWrapper *sound in _nodesInArrangement) {
                if (![arrangementCopy containsObject:sound]) {
                    continue;
                }
                if (currentX >= (sound.node.position.x - 0.1/2)) {
                    [_soundManager playSound:kSnareKey];
                    [arrangementCopy removeObject:sound];
                }
            }
            timeSinceAnimation += loopPanningDuration;
            [NSThread sleepForTimeInterval:loopPanningDuration];
        }
    });
}

-(void) startPanningArrangement:(float)bpm
{
    float bps = bpm / 60.0; // beats per second
    float totalPanningDuration = (float)kNumMeasures / bps;
    const float loopPanningDuration = totalPanningDuration / (float)kAnimateQuantize;
    //const float panSpeed = kPLANE_WIDTH / totalPanningDuration;
    
    const float constY = _orthoPlaneNode.position.y;
    const float constZ = _orthoPlaneNode.position.z;

    _isAnimating = YES;
    SCNAction *pan = [SCNAction moveByX:kPLANE_WIDTH y:0 z:0 duration:totalPanningDuration];
    [_orthoPlaneNode runAction:pan completionHandler:^{
        _isAnimating = NO;
        _orthoPlaneNode.position = SCNVector3Make(0.0-kPLANE_WIDTH/2, constY, constZ);
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^void () {
        float timeSinceAnimation = 0.0;
        BOOL hasNewWaves = NO;
        while (_isAnimating) {
            float currentX = _orthoPlaneNode.position.x;
            [_arrayLock lock];
            if ([_addedWaves count] > 0) {
                hasNewWaves = YES;
                [_addedWaves removeAllObjects];
            }
            [_arrayLock unlock];
            
            if (hasNewWaves) {
                SCNBox *boxGeometry = [SCNBox boxWithWidth:0.1
                                                    height:0.1
                                                    length:0.1
                                             chamferRadius:0.0];
                SCNNode *boxNode = [SCNNode nodeWithGeometry:boxGeometry];
                boxNode.position = SCNVector3Make(currentX + 0.1/2.0, constY, constZ);
                [self.sceneView.scene.rootNode addChildNode: boxNode];
                SCNNodeWrapper *nodeWrapper = [SCNNodeWrapper new];
                nodeWrapper.soundKey = kSnareKey;
                nodeWrapper.node = boxNode;
                [_nodesInArrangement addObject:nodeWrapper];
                hasNewWaves = NO;
            }
            timeSinceAnimation += loopPanningDuration;
            [NSThread sleepForTimeInterval:loopPanningDuration];
        }
    });
    
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

#pragma mark - Grid Setup

// Set up the Grid used to anchor all patterns
- (void)setupGrid
{
    // Initialize the material
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"tron_grid"];
    material.diffuse.contents = img;
    material.doubleSided = YES;
    
    // Set up horizontal planes
    SCNMaterial *materialH = [material copy];
    materialH.diffuse.contentsTransform = SCNMatrix4MakeScale(kPLANE_WIDTH, kPLANE_HEIGHT, 1);
    materialH.diffuse.wrapS = SCNWrapModeRepeat;
    materialH.diffuse.wrapT = SCNWrapModeRepeat;
    SCNPlane *planeGeometry = [SCNPlane planeWithWidth:kPLANE_WIDTH height:kPLANE_HEIGHT];
    planeGeometry.materials = @[materialH];
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:planeGeometry];
    
    // Rotate the plane (it's vertical by default)
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI / 2.0, 1.0, 0.0, 0.0);
    
    // place it 1 meter in front of the camera
    planeNode.position = SCNVector3Make(kPLANE_X, kPLANE_Y, kPLANE_Z);
    
    [self.sceneView.scene.rootNode addChildNode:planeNode];
    
    // Setup vertical plane
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(kPLANE_HEIGHT, kORTH_PLANE_HEIGHT, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.diffuse.wrapT = SCNWrapModeRepeat;
    SCNPlane *vertPlane = [SCNPlane planeWithWidth:kPLANE_HEIGHT height:kORTH_PLANE_HEIGHT];
    vertPlane.materials = @[material];
    
    SCNNode *vertPlaneNode = [SCNNode nodeWithGeometry:vertPlane];
    
    // Rotate the plane along y axis
    vertPlaneNode.transform = SCNMatrix4MakeRotation(-M_PI / 2.0, 0.0, 1.0, 0.0);
    
    // place it 1 meter in front of the camera
    vertPlaneNode.position = SCNVector3Make(0.0-kPLANE_WIDTH/2, kPLANE_Y+kORTH_PLANE_HEIGHT/2, kPLANE_Z);
    
    [self.sceneView.scene.rootNode addChildNode:vertPlaneNode];
}

- (void)setUpOrthoMovingPlane
{
    SCNPlane *planeGeometry = [SCNPlane planeWithWidth:kPLANE_HEIGHT height:kORTH_PLANE_HEIGHT];
    planeGeometry.firstMaterial.doubleSided = YES;
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:planeGeometry];
    
    // Rotate the plane along y axis
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI / 2.0, 0.0, 1.0, 0.0);
    
    // place it 1 meter in front of the camera
    planeNode.position = SCNVector3Make(0.0-kPLANE_WIDTH/2, kPLANE_Y+kORTH_PLANE_HEIGHT/2, kPLANE_Z);
    
    // TODO add texture scale
    planeNode.opacity = 0.5;
    
    _orthoPlaneNode = planeNode;

    [self.sceneView.scene.rootNode addChildNode:_orthoPlaneNode];
}

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
