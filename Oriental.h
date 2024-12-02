#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface CAPackage : NSObject
+ (id)packageWithContentsOfURL:(id)arg1 type:(id)arg2 options:(id)arg3 error:(id)arg4;
@end

@interface CCUICAPackageView : UIView
@property (nonatomic, retain) CAPackage *package;
- (void)setStateName:(id)arg1;
@end

@interface SBOrientationLockManager : NSObject
+ (id)sharedInstance;
- (void)unlock;
- (void)lock;
- (BOOL)isUserLocked;
@end

@interface SBApplicationInfo : NSObject
  -(BOOL)supportsInterfaceOrientation:(NSInteger)orientation;
  -(BOOL)hasHiddenTag;
@end

@interface SBApplication
  @property (nonatomic,readonly) NSString * bundleIdentifier;
  @property (nonatomic,retain) SBApplicationInfo * info;
@end

@interface SBFTouchPassThroughViewController : UIViewController
@end

@interface OrientalIndicatorWindow : UIWindow
    + (OrientalIndicatorWindow *)sharedWindow;
@end

@interface SBTraitsEmbeddedDisplayPipelineManager
  -(BOOL)shouldProcessEventsForOrientation:(int)orientation;
@end

@interface SpringBoard : UIApplication
  @property (nonatomic, retain) UIView *orientalIndicatorView;
  @property (nonatomic, strong) NSTimer *orientalViewTimer;
  -(SBApplication*)_accessibilityFrontMostApplication;
  -(long long)_frontMostAppOrientation;
  - (void)resetOrientalState;
  -(BOOL)isLocked;
@end
