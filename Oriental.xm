#import "Oriental.h"

extern NSString const *kCAPackageTypeCAMLBundle;

@implementation OrientalIndicatorWindow

    + (OrientalIndicatorWindow *)sharedWindow {
        static OrientalIndicatorWindow *sharedWindow = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedWindow = [[self alloc] init];
        });
        return sharedWindow;
    }

    - (OrientalIndicatorWindow *)init {
        self = [super init];
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = UIColor.clearColor;
        self.windowLevel = UIWindowLevelStatusBar;
        self.layer.masksToBounds = true;
        self.rootViewController = [NSClassFromString(@"SBFTouchPassThroughViewController") new];
        self.hidden = NO;
        return self;
    }

    // Passthrough
    - (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
        UIView *view = [super hitTest:point withEvent:event];
        return view == self ? nil : view;
    }
@end

static BOOL isOrientationUnlockedByTweak = NO;

static BOOL isOrientationLocked() {
    return [[%c(SBOrientationLockManager) sharedInstance] isUserLocked];
}

static void setOrientationLock(BOOL lock) {
    lock ? [[%c(SBOrientationLockManager) sharedInstance] lock] : [[%c(SBOrientationLockManager) sharedInstance] unlock];
}

%hook SpringBoard
    %property (nonatomic, retain) UIView *orientalIndicatorView;
    %property (nonatomic, strong) NSTimer *orientalViewTimer;        

    - (void)applicationDidFinishLaunching:(id)application {
        %orig;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOrientalIndicatorViewForOrientation:) name:@"showOrientalIndicatorView" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetOrientalState) name:@"resetOrientalState" object:nil];

        setOrientationLock(YES);

        self.orientalIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(30, ([UIScreen mainScreen].bounds.size.height / 2) - 40, 80, 80)];
        self.orientalIndicatorView.alpha = 1.0;
        self.orientalIndicatorView.hidden = YES;
        self.orientalIndicatorView.layer.cornerRadius = 16.0;
        self.orientalIndicatorView.layer.masksToBounds = YES;
        [self.orientalIndicatorView setBackgroundColor:[UIColor clearColor]];
        //[self.orientalIndicatorView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.orientalIndicatorView setUserInteractionEnabled:YES];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.alpha = 1.0;
        blurEffectView.frame = self.orientalIndicatorView.bounds;
        [self.orientalIndicatorView addSubview:blurEffectView];

        CCUICAPackageView *glyphView = [[%c(CCUICAPackageView) alloc] initWithFrame:self.orientalIndicatorView.bounds];
        glyphView.package = [CAPackage packageWithContentsOfURL:[NSURL fileURLWithPath:@"/System/Library/ControlCenter/Bundles/OrientationLockModule.bundle/OrientationLock.ca"] type:kCAPackageTypeCAMLBundle options:nil error:nil];
        [self.orientalIndicatorView addSubview:glyphView];
        [glyphView.centerXAnchor constraintEqualToAnchor:self.orientalIndicatorView.centerXAnchor].active = YES;
        [glyphView.centerYAnchor constraintEqualToAnchor:self.orientalIndicatorView.centerYAnchor].active = YES;

        UITapGestureRecognizer *tapToToggleLock = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unlockOrientationTapped:)];
        [self.orientalIndicatorView addGestureRecognizer:tapToToggleLock];
        
        [[OrientalIndicatorWindow sharedWindow].rootViewController.view addSubview:self.orientalIndicatorView];
    }

    %new
    - (void)resetOrientalState {
        if (self.orientalViewTimer != nil) {
            [self.orientalViewTimer invalidate];
            self.orientalViewTimer = nil;
        }
        [UIView transitionWithView:self.orientalIndicatorView
                  duration:0.4
                   options:UIViewAnimationOptionTransitionCrossDissolve
                animations:^{
                    self.orientalIndicatorView.alpha = 0.0;
                }
                completion:^(BOOL finished){self.orientalIndicatorView.hidden = YES;}];                
        isOrientationUnlockedByTweak = NO; 
    }    

    %new
    - (void)unlockOrientationTapped:(UITapGestureRecognizer *)gestureRecognizer {
        [self resetOrientalState];
        setOrientationLock(NO);
        isOrientationUnlockedByTweak = YES;        
    }

    %new
    - (void)showOrientalIndicatorViewForOrientation:(NSNotification *)notification {        
        NSDictionary* userInfo = notification.userInfo;
        int orientation = [userInfo[@"orientation"] intValue];        

        //NSLog(@"KPD showing view for orientation %d",orientation);
        if (orientation == 3) {
            self.orientalIndicatorView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100), ([UIScreen mainScreen].bounds.size.height / 2) - 40, 80, 80);
            self.orientalIndicatorView.transform = CGAffineTransformMakeRotation(90 * M_PI/180);
        }
        else {
            self.orientalIndicatorView.frame = CGRectMake(20, ([UIScreen mainScreen].bounds.size.height / 2) - 40, 80, 80);
            self.orientalIndicatorView.transform = CGAffineTransformMakeRotation(270 * M_PI/180);
        }

        self.orientalIndicatorView.alpha = 1.0;

        [UIView transitionWithView:self.orientalIndicatorView
                  duration:0.4
                   options:UIViewAnimationOptionTransitionCrossDissolve
                animations:^{
                     self.orientalIndicatorView.hidden = NO;
                }
                completion:NULL];

        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedbackGenerator impactOccurred];                

        self.orientalViewTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(resetOrientalState) userInfo:nil repeats:NO];      
    }     

%end

int lastOrientation = 1;

%hook SBTraitsEmbeddedDisplayPipelineManager 

	-(void)accelerometer:(id)arg1 didChangeDeviceOrientation:(NSInteger)currentOrientation {
		%orig;

        if (![self shouldProcessEventsForOrientation:currentOrientation])
            return;

		// 1 - Portrait
		// 2 - Portrait Upside down
		// 3 - Landscape Left
		// 4 - Landscape Right
		// 5 - Flat Faceup
		// 6 - Flat Facedown
		if (currentOrientation == 3 || currentOrientation == 4) {
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentOrientation] forKey:@"orientation"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showOrientalIndicatorView" object:self userInfo:userInfo];
        }
        else {
            if ((lastOrientation == 3 || lastOrientation == 4) && (currentOrientation == 1 || currentOrientation == 2) && isOrientationUnlockedByTweak) {
                setOrientationLock(YES);
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:@"resetOrientalState" object:self userInfo:nil];            
        }

        lastOrientation = currentOrientation;
	}

    %new
    -(BOOL)shouldProcessEventsForOrientation:(int)orientation {

        if (!isOrientationLocked() && !isOrientationUnlockedByTweak)
            return NO;

        SpringBoard *sb = (SpringBoard *)[UIApplication sharedApplication];
        id topPresentedApp = [sb _accessibilityFrontMostApplication];
        BOOL isDeviceLocked = [sb isLocked];
        UIDeviceOrientation appOrientation = [sb _frontMostAppOrientation];

        if (isDeviceLocked || topPresentedApp == nil || appOrientation != UIDeviceOrientationPortrait) {
            // tweak disabled
            // device is locked 
            // there's no app in foreground
            // ==> quit
            return NO;
        }
        
        SBApplicationInfo *appInfo = ((SBApplication *)topPresentedApp).info;
        return ![appInfo hasHiddenTag] && [appInfo supportsInterfaceOrientation:orientation];
    }

%end
