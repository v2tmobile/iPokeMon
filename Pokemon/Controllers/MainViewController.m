//
//  MainViewController.m
//  Pokemon
//
//  Created by Kaijie Yu on 1/31/12.
//  Copyright (c) 2012 Kjuly. All rights reserved.
//

#import "MainViewController.h"

#import "GlobalConstants.h"
#import "GlobalNotificationConstants.h"
#import "GlobalRender.h"
#import "CenterMainButtonTouchDownCircleView.h"
#import "Trainer+DataController.h"
#import "TrainerTamedPokemon+DataController.h"
#import "MapViewController.h"
#import "UtilityViewController.h"
#import "PoketchTabViewController.h"
#import "CustomNavigationController.h"
#import "CenterMenuUtilityViewController.h"
#import "GameMainViewController.h"

#ifdef DEBUG
#import "Pokemon+DataController.h"
#import "Move+DataController.h"
#import "WildPokemon+DataController.h"
#endif


// For sign |centerMainButton_| status
typedef enum {
  kCenterMainButtonStatusNormal   = 0,
  kCenterMainButtonStatusAtBottom = 1
}CenterMainButtonStatus;

@interface MainViewController () {
 @private
  CenterMenuUtilityViewController * centerMenuUtilityViewController_;
  CenterMainButtonTouchDownCircleView * centerMainButtonTouchDownCircleView_;
 
  UIButton             * currentKeyButton_;
  CenterMainButtonStatus centerMainButtonStatus_;
  BOOL                   isCenterMenuOpening_;
  NSTimer              * centerMenuOpenStatusTimer_;
  BOOL                   isCenterMainButtonTouchDownCircleViewLoading_;
  BOOL                   isMapViewOpening_;
  NSTimer              * longTapTimer_;
  NSInteger              centerMenuOpenStatusTimeCounter_;
  NSInteger              timeCounter_;
}

@property (nonatomic, retain) CenterMenuUtilityViewController * centerMenuUtilityViewController;
@property (nonatomic, retain) CenterMainButtonTouchDownCircleView * centerMainButtonTouchDownCircleView;

@property (nonatomic, retain) UIButton             * currentKeyButton;
@property (nonatomic, assign) CenterMainButtonStatus centerMainButtonStatus;
@property (nonatomic, assign) BOOL                   isCenterMenuOpening;
@property (nonatomic, retain) NSTimer              * centerMenuOpenStatusTimer;
@property (nonatomic, assign) BOOL                   isCenterMainButtonTouchDownCircleViewLoading;
@property (nonatomic, assign) BOOL                   isMapViewOpening;
@property (nonatomic, retain) NSTimer              * longTapTimer;
@property (nonatomic, assign) NSInteger              centerMenuOpenStatusTimeCounter;
@property (nonatomic, assign) NSInteger              timeCounter;

- (void)changeCenterMainButtonStatus:(NSNotification *)notification;
- (void)runCenterMainButtonTouchUpInsideAction:(id)sender;
- (void)openCenterMenuView;
- (void)closeCenterMenuView;
- (void)activateCenterMenuOpenStatusTimer;
- (void)deactivateCenterMenuOpenStatusTimer;
- (void)closeCenterMenuWhenLongTimeNoOperation;
- (void)countLongTapTimeWithAction:(id)sender;
- (void)increaseTimeWithAction;
- (void)toggleMapView:(id)sender;
- (void)toggleLocationService;
- (void)resetMainView;

@end


@implementation MainViewController

@synthesize centerMainButton = centerMainButton_;
@synthesize mapButton        = mapButton_;

@synthesize mapViewController           = mapViewController_;
@synthesize utilityViewController       = utilityViewController_;
@synthesize poketchViewController       = poketchViewController_;
@synthesize utilityNavigationController = utilityNavigationController_;
@synthesize gameMainViewController      = gameMainViewController_;

@synthesize centerMenuUtilityViewController = centerMenuUtilityViewController_;
@synthesize centerMainButtonTouchDownCircleView = centerMainButtonTouchDownCircleView_;

@synthesize currentKeyButton                = currentKeyButton_;
@synthesize centerMainButtonStatus          = centerMainButtonStatus_;
@synthesize isCenterMenuOpening             = isCenterMenuOpening_;
@synthesize centerMenuOpenStatusTimer       = centerMenuOpenStatusTimer_;
@synthesize isCenterMainButtonTouchDownCircleViewLoading = isCenterMainButtonTouchDownCircleViewLoading_;
@synthesize isMapViewOpening                = isMapViewOpening_;
@synthesize longTapTimer                    = longTapTimer_;
@synthesize centerMenuOpenStatusTimeCounter = centerMenuOpenStatusTimeCounter_;
@synthesize timeCounter                     = timeCounter_;

- (void)dealloc
{
  [centerMainButton_ release];
  [mapButton_        release];
  
  [mapViewController_ release];
  [utilityViewController_ release];
  [poketchViewController_ release];
  [utilityNavigationController_ release];
  [gameMainViewController_ release];
  
  self.centerMenuUtilityViewController = nil;
  self.centerMainButtonTouchDownCircleView = nil;
  
  self.currentKeyButton = nil;
  
  [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
#if DEBUG
    if (kPupulateData) {
      // Hard Initialize the DB Data for |Pokemon|
      [Pokemon populateData];
      [Move populateData];
    }
#endif
    
    // Updata all data for current User with the trainer ID
    [Trainer updateDataForTrainer:1];
    [TrainerTamedPokemon updateDataForTrainer:1];
    [WildPokemon updateDataForCurrentRegion:1];
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
  [super loadView];
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  
  UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 480.0f)];
  self.view = view;
  [view release];
  
  [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"MainViewBackgroundBlack.png"]]];
  [self.view setOpaque:NO];
  
  // Base iVar Settings
  centerMainButtonStatus_ = kCenterMainButtonStatusNormal;
  isCenterMenuOpening_    = NO;
  isCenterMainButtonTouchDownCircleViewLoading_ = NO;
  isMapViewOpening_       = NO;
  
  
  // Add self as Notification observer
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeCenterMainButtonStatus:)
                                               name:kPMNChangeCenterMainButtonStatus
                                             object:nil];
  
  // Ball menu which locate at center
  UIButton * centerMainButton = [[UIButton alloc] initWithFrame:CGRectMake((320.0f - kCenterMainButtonSize) / 2,
                                                                           (480.0f - kCenterMainButtonSize) / 2,
                                                                           kCenterMainButtonSize,
                                                                           kCenterMainButtonSize)];
  
  self.centerMainButton = centerMainButton;
  [centerMainButton release];
  [self.centerMainButton setContentMode:UIViewContentModeScaleAspectFit];
  [self.centerMainButton setBackgroundImage:[UIImage imageNamed:@"MainViewCenterButtonBackground.png"]
                                   forState:UIControlStateNormal];
  [self.centerMainButton setImage:[UIImage imageNamed:@"MainViewCenterButtonImageNormal.png"] forState:UIControlStateNormal];
  [self.centerMainButton setOpaque:NO];
  [self.centerMainButton setTag:kTagMainViewCenterMainButton];
  [self.view addSubview:self.centerMainButton];
  
  // Register touch events for |centerMainButton_|
  [self.centerMainButton addTarget:self
                            action:@selector(runCenterMainButtonTouchUpInsideAction:)
                  forControlEvents:UIControlEventTouchUpInside];
  [self.centerMainButton addTarget:self
                            action:@selector(countLongTapTimeWithAction:)
                  forControlEvents:UIControlEventTouchDown];
  
  // Map Button
  UIButton * mapButton = [[UIButton alloc] initWithFrame:CGRectMake((320.0f - kMapButtonSize) / 2,
                                                                    100.0f,
                                                                    kMapButtonSize,
                                                                    kMapButtonSize)];
  self.mapButton = mapButton;
  [mapButton release];
  [self.mapButton setContentMode:UIViewContentModeScaleAspectFit];
  [self.mapButton setBackgroundImage:[UIImage imageNamed:@"MainViewMapButtonBackground.png"]
                            forState:UIControlStateNormal];
  [self.mapButton setImage:[UIImage imageNamed:@"MainViewMapButtonImageNormal.png"] forState:UIControlStateNormal];
  [self.mapButton setOpaque:NO];
  [self.mapButton setTag:kTagMainViewMapButton];
  [self.mapButton addTarget:self action:@selector(toggleMapView:) forControlEvents:UIControlEventTouchUpInside];
  [self.mapButton addTarget:self action:@selector(countLongTapTimeWithAction:) forControlEvents:UIControlEventTouchDown];
  [self.view addSubview:self.mapButton];

/*
  // Poketch( Short for Pocket Watch ) View Controller
  PoketchTabViewController * pocktchViewController = [[PoketchTabViewController alloc] init];
  self.poketchViewController = pocktchViewController;
  [pocktchViewController release];
  [self.view addSubview:self.poketchViewController.view];
  
  // Utility View Controller
  UtilityViewController * utilityViewController = [[UtilityViewController alloc] init];
  self.utilityViewController = utilityViewController;
  [utilityViewController release];
  // Set |mapViewController_| as |utilityViewController_|'s |delegate|,
  // for |buttonLocateMe| & |buttonShowWorld|
  self.utilityViewController.delegate = (id <UtilityViewControllerDelegate>)self.mapViewController;
  [self.view addSubview:self.utilityViewController.view];
  
  // Game Main View
//  gameMainViewController_ = [[GameMainViewController alloc] init];
//  [self.view addSubview:gameMainViewController_.view];
*/
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  
  self.centerMainButton = nil;
  self.mapButton        = nil;
  
  self.mapViewController = nil;
  self.utilityViewController = nil;
  self.poketchViewController = nil;
  self.utilityNavigationController = nil;
  self.gameMainViewController = nil;
  
  self.centerMenuUtilityViewController = nil;
  
  [self.longTapTimer invalidate];
  self.longTapTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private Methods

// Slide |centerMainButton_| to view bottom when button in center menu is clicked
- (void)changeCenterMainButtonStatus:(NSNotification *)notification
{
  switch ([[notification.userInfo objectForKey:@"centerMainButtonStatus"] intValue]) {
    case kCenterMainButtonStatusAtBottom:
      self.centerMainButtonStatus = kCenterMainButtonStatusAtBottom;
      [UIView animateWithDuration:0.3f
                            delay:0.0f
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         CGRect centerMainButtonFrame = self.centerMainButton.frame;
                         centerMainButtonFrame.origin.y = 480.0f - kCenterMainButtonSize / 2;
                         [self.centerMainButton setFrame:centerMainButtonFrame];
                         
                         // Hide |mapButton_|
                         CGRect mapButtonFrame = self.mapButton.frame;
                         mapButtonFrame.origin.y = - kMapButtonSize;
                         [self.mapButton setFrame:mapButtonFrame];
                       }
                       completion:nil];
      [self deactivateCenterMenuOpenStatusTimer];
      break;
      
    default:
      self.centerMainButtonStatus = kCenterMainButtonStatusNormal;
      [UIView animateWithDuration:0.3f
                            delay:0.0f
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         CGRect centerMainButtonFrame = self.centerMainButton.frame;
                         centerMainButtonFrame.origin.y = (480.0f - kCenterMainButtonSize) / 2;
                         [self.centerMainButton setFrame:centerMainButtonFrame];
                       }
                       completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3f
                                               delay:0.0f
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                            // Hide navigation bar
//                                            [self.centerMenuUtilityViewController.navigationController setNavigationBarHidden:YES animated:NO];
                                            
                                            // Show |mapButton_|
                                            CGRect mapButtonFrame = self.mapButton.frame;
                                            mapButtonFrame.origin.y = - kMapButtonSize / 2;
                                            [self.mapButton setFrame:mapButtonFrame];
                                          }
                                          completion:nil];
                       }];
      // Is |centerMenu_| is opening, activate |centerMenuOpenStatusTimer_|
      if (self.isCenterMenuOpening) [self activateCenterMenuOpenStatusTimer];
      break;
  }
}

// |centerMainButton_| touch up inside action
- (void)runCenterMainButtonTouchUpInsideAction:(id)sender
{
  switch (self.centerMainButtonStatus) {
    case kCenterMainButtonStatusNormal:
      if (self.isCenterMenuOpening) [self closeCenterMenuView];
      else {
        [self openCenterMenuView];
        
        // Activate |centerMenuOpenStatusTimer_|
        [self activateCenterMenuOpenStatusTimer];
      }
      
      self.isCenterMenuOpening = ! self.isCenterMenuOpening;
      break;
      
    case kCenterMainButtonStatusAtBottom:
      [[NSNotificationCenter defaultCenter] postNotificationName:kPMNBackToMainView object:self userInfo:nil];
      break;
      
    default:
      break;
  }
}

// Method for opening center menu view when |isCenterMenuOpening_ == NO|
- (void)openCenterMenuView
{
  [self.longTapTimer invalidate];
  
  // Stop |centerMainButtonTouchDownCircleView_| loading
  [self.centerMainButtonTouchDownCircleView stopAnimation];
  self.isCenterMainButtonTouchDownCircleViewLoading = NO;
  
  // Do action based on tap down keepped time
  if (self.timeCounter < 3.0f) {
    if (! self.utilityNavigationController) {
      NSLog(@"--- MainViewController openBallMenuView if(!): Create new CustomNavigationController ---");
      if (! self.centerMenuUtilityViewController) {
        CenterMenuUtilityViewController * centerMenuUtilityViewController = [[CenterMenuUtilityViewController alloc]
                                                                             initWithButtonCount:6];
        self.centerMenuUtilityViewController = centerMenuUtilityViewController;
        [centerMenuUtilityViewController release];
      }
      
      utilityNavigationController_ = [CustomNavigationController
                                      initWithRootViewController:self.centerMenuUtilityViewController
                                    navigationBarBackgroundImage:[UIImage imageNamed:@"NavigationBarBackgroundBlue.png"]];
    }
    
    // Insert |utilityNavigationController|'s view
    [self.view insertSubview:self.utilityNavigationController.view belowSubview:self.centerMainButton];
    
    // |mapButton_|'s new Frame
    CGRect mapButtonFrame = self.mapButton.frame;
    mapButtonFrame.origin.y = - kMapButtonSize / 2;
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                       [self.mapButton setFrame:mapButtonFrame];
                     }
                     completion:^(BOOL finished) {
                       [self.centerMenuUtilityViewController openCenterMenuView];
                       // iOS4 will not call |viewWillAppear:| when the VC is a child of another VC
                       //if (SYSTEM_VERSION_LESS_THAN(@"5.0"))
                       //  [self.centerMenuUtilityViewController viewWillAppear:YES];
                     }];
  }
  else if (self.timeCounter <= 2) {
    NSLog(@"1 < time <= 2");
  }
  else self.isCenterMenuOpening = NO; // !!! Need to be remove
}

// Method for close center menu view when |isCenterMenuOpening_ == YES|
- (void)closeCenterMenuView
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kPMNCloseCenterMenu
                                                      object:self
                                                    userInfo:nil];
  [self resetMainView];
  [self deactivateCenterMenuOpenStatusTimer];
}

// Activate |centerMenuOpenStatusTimer_| to count how many time the |centerMenu_| is open without any operation,
// Close the |centerMenu_| when necessary
- (void)activateCenterMenuOpenStatusTimer
{
  self.centerMenuOpenStatusTimeCounter = 0;
  self.centerMenuOpenStatusTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                    target:self
                                                                  selector:@selector(closeCenterMenuWhenLongTimeNoOperation)
                                                                  userInfo:nil
                                                                   repeats:YES];
}

// Stop |centerMenuOpenStatusTimer_| when button clicked
- (void)deactivateCenterMenuOpenStatusTimer {
  [self.centerMenuOpenStatusTimer invalidate];
}

// Close |centerMenu_| when long time no operation 
- (void)closeCenterMenuWhenLongTimeNoOperation
{
  self.centerMenuOpenStatusTimeCounter += 5;
  NSLog(@"%d", self.centerMenuOpenStatusTimeCounter);
  if (self.centerMenuOpenStatusTimeCounter == 10) {
    [self closeCenterMenuView];
    self.isCenterMenuOpening = NO;
    [self.centerMenuOpenStatusTimer invalidate];
  }
}

// |centerMainButton_| touch down action
- (void)countLongTapTimeWithAction:(id)sender
{
  if (! self.isCenterMenuOpening) {
    // Start time counting
    self.currentKeyButton = (UIButton *)sender;
    self.timeCounter  = 0;
    [self.longTapTimer invalidate];
    self.longTapTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                         target:self
                                                       selector:@selector(increaseTimeWithAction)
                                                       userInfo:nil
                                                        repeats:YES];
  }
}

// Method for counting Tap Down time
- (void)increaseTimeWithAction
{
  ++self.timeCounter;
  NSLog(@"Touch Keep Time: %d", self.timeCounter);
  
  NSInteger buttonTag = self.currentKeyButton.tag;
  
  // If the target is |centerMainButton_|, add |timeCounter_ >= 1.0|, loading it
  // Time: delay 1.0 second, then every 2.0 second got a new point
  if (! self.isCenterMainButtonTouchDownCircleViewLoading && buttonTag == kTagMainViewCenterMainButton
      && ! self.isCenterMenuOpening && self.timeCounter >= 1.0f)
  {
    // Run this block after |mapButton_| moved to view top
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
      NSLog(@"increaseTimeWithAction - Start loading |centerMainButtonTouchDownCircleView|...");
      self.isCenterMainButtonTouchDownCircleViewLoading = YES;
      
      // Loading |centerMainButtonTouchDownCircleView_|
      if (! self.centerMainButtonTouchDownCircleView) {
        CenterMainButtonTouchDownCircleView * centerMainButtonTouchDownCircleView
        = [[CenterMainButtonTouchDownCircleView alloc]
           initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - kCenterMainButtonTouchDownCircleViewSize / 2,
                                    CGRectGetMidY(self.view.frame) - kCenterMainButtonTouchDownCircleViewSize / 2,
                                    kCenterMainButtonTouchDownCircleViewSize,
                                    kCenterMainButtonTouchDownCircleViewSize)];
        self.centerMainButtonTouchDownCircleView = centerMainButtonTouchDownCircleView;
        [centerMainButtonTouchDownCircleView release];
      }
      [self.view insertSubview:self.centerMainButtonTouchDownCircleView belowSubview:self.centerMainButton];
      [self.centerMainButtonTouchDownCircleView startAnimation];
    };
    
    // Move |mapButton_| to view top
    CGRect mapButtonFrame = self.mapButton.frame;
    mapButtonFrame.origin.y = - kMapButtonSize / 2;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                       [self.mapButton setFrame:mapButtonFrame];
                     }
                     completion:completionBlock];
  }
  
  // If keep tapping the |mapButton_| long time until... do |toggleLocationService|
  else if (buttonTag == kTagMainViewMapButton && self.timeCounter >= 3.0f) {
    [self toggleLocationService];
    [self.longTapTimer invalidate];
  }
}

// |mapButton_| action
- (void)toggleMapView:(id)sender
{
  [self.longTapTimer invalidate];
  // If Location Service is not allowed, do nothing
  if (! [[NSUserDefaults standardUserDefaults] boolForKey:@"keyAppSettingsLocationServices"] || self.timeCounter >= 6.0f)
    return;
  
  // Else, just normal button action
  CGRect mapViewFrame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f);
  CGRect mapButtonFrame = self.mapButton.frame;
  
  if (self.isMapViewOpening) {
    mapViewFrame.origin.y   = 480.0f;
    mapButtonFrame.origin.y = 100.0f;
  }
  else {
    mapButtonFrame.origin.y = - kMapButtonSize / 2;
    
    if (! self.mapViewController) {
      NSLog(@"--- MainViewController openMapView if(!): Create |mapViewController_| ---");
      MapViewController * mapViewController = [[MapViewController alloc] init];
      self.mapViewController = mapViewController;
      [mapViewController release];
    }
    [self.view insertSubview:self.mapViewController.view belowSubview:self.mapButton];
    
    // Set Map View to Offscreen
    mapViewFrame.origin.y = 480.0f;
    [self.mapViewController.view setFrame:mapViewFrame];
    mapViewFrame.origin.y = 0.0f;
  }
  
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     // If |mapView| is not open while |centerMenu_| is open, just close |centerMenu_|
                     // Else, set |mapButton_| to view top
                     if (! self.isMapViewOpening && self.isCenterMenuOpening) {
                       [[NSNotificationCenter defaultCenter] postNotificationName:kPMNCloseCenterMenu
                                                                           object:self
                                                                         userInfo:nil];
                       self.isCenterMenuOpening = NO;
                       [self deactivateCenterMenuOpenStatusTimer];
                     }
                     else [self.mapButton setFrame:mapButtonFrame];
                       
                     // Set frame of the |mapViewController_|'s view to show it
                     [self.mapViewController.view setFrame:mapViewFrame];
                   }
                   completion:^(BOOL finished) {                     
                     self.isMapViewOpening = ! self.isMapViewOpening;
                     
                     if (self.isMapViewOpening)
                       [self.mapButton setImage:[UIImage imageNamed:@"MainViewMapButtonImageHalfCancel.png"]
                                       forState:UIControlStateNormal];
                     else {
                       [self.mapButton setImage:[UIImage imageNamed:@"MainViewMapButtonImageNormal.png"]
                                       forState:UIControlStateNormal];
                       [self.mapViewController.view removeFromSuperview];
                     }
                   }];
}

// Toggle Location Service after long press on |mapButton_|
- (void)toggleLocationService
{
  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
  if ([userDefaults boolForKey:@"keyAppSettingsLocationServices"]) {
    NSLog(@"Service is on, turn off");
    [userDefaults setBool:NO forKey:@"keyAppSettingsLocationServices"];
    [self.mapButton setImage:[UIImage imageNamed:@"MainViewMapButtonImageLBSDisabled.png"] forState:UIControlStateNormal];
  }
  else {
    NSLog(@"Service is off, turn on");
    [userDefaults setBool:YES forKey:@"keyAppSettingsLocationServices"];
    [self.mapButton setImage:[UIImage imageNamed:@"MainViewMapButtonImageNormal.png"] forState:UIControlStateNormal];
  }
  NSLog(@"%d", [[userDefaults objectForKey:@"keyAppSettingsLocationServices"] intValue]);
}

// Notification action methods
- (void)resetMainView
{
  // |mapButton_|'s original Frame
  CGRect mapButtonFrame = self.mapButton.frame;
  mapButtonFrame.origin.y = 100.0f;
  
  [UIView animateWithDuration:0.3f
                        delay:0.0f
                      options:UIViewAnimationCurveEaseInOut
                   animations:^{
                     [self.mapButton setFrame:mapButtonFrame];
                   }
                   completion:nil];
}

@end
