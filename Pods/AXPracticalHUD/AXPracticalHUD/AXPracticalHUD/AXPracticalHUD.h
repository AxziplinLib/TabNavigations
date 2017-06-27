//
//  AXPracticalHUD.h
//  AXSwift2OC
//
//  Created by ai on 9/7/15.
//  Copyright © 2015 ai. All rights reserved.
//

#import "AXBarProgressView.h"
#import "AXCircleProgressView.h"
#import "AXGradientProgressView.h"
#import "AXPracticalHUDContentView.h"

/// Mode of hud view
typedef NS_ENUM(NSInteger, AXPracticalHUDMode) {
    /// Progress is shown using an UIActivityIndicatorView. This is the default.
    AXPracticalHUDModeIndeterminate,
    /// Progress is shown using a round, pie-chart like, progress view.
    AXPracticalHUDModeDeterminate,
    /// Progress is shown using a horizontal progress bar
    AXPracticalHUDModeDeterminateHorizontalBar,
    /// Progress is shown using a horizontal colorful progress bar
    AXPracticalHUDModeDeterminateColorfulHorizontalBar,
    /// Progress is shown using a ring-shaped progress view.
    AXPracticalHUDModeDeterminateAnnularEnabled,
    /// Shows a custom view
    AXPracticalHUDModeCustomView,
    /// Shows only labels
    AXPracticalHUDModeText,
    /// Progress is shown using an breach annular indicator.
    AXPracticalHUDModeBreachedAnnularIndeterminate
};
/// Animation styles of hud view animating.
typedef NS_ENUM(NSInteger, AXPracticalHUDAnimation) {
    /// Using fade animation.
    AXPracticalHUDAnimationFade,
    /// Using flip in animation.
    AXPracticalHUDAnimationFlipIn
};
/// Position of hud view.
typedef NS_ENUM(NSInteger, AXPracticalHUDPosition) {
    /// Top position.
    AXPracticalHUDPositionTop,
    /// Center position.
    AXPracticalHUDPositionCenter,
    /// Bottom position
    AXPracticalHUDPositionBottom
};
/// Completion block when task finished.
typedef void(^AXPracticalHUDCompletionBlock)();
/// HUD delegate
@protocol AXPracticalHUDDelegate;

@interface AXPracticalHUD : UIView
/// Delegate of HUD view,
@property(assign, nonatomic) id<AXPracticalHUDDelegate>delegate;
#pragma mark - Boolean
/// Restore the hud view when hud hided if YES, setting the properties of hud view to the initial state. Default is NO.
@property(assign, nonatomic) BOOL restoreEnabled;
/// Lock the background to avoid the touch events if YES. Default is NO.
@property(assign, nonatomic) BOOL lockBackground;
/// Using dim background if YES. Default is NO.
@property(assign, nonatomic) BOOL dimBackground;
/// Remove the hud from super view if hud is hidden. Default is YES.
@property(assign, nonatomic) BOOL removeFromSuperViewOnHide;
/// Using the square content view if YES. Default is NO.
@property(assign, nonatomic, getter=isSquare) BOOL square;
#pragma mark - Frame.
/// Total size of hud container view. Read only.
@property(readonly, nonatomic) CGSize size;
/// Margin of content views. Default is 15.0f.
@property(assign, nonatomic) CGFloat margin;
/// Offset of cotent view. Default is zero.
@property(assign, nonatomic) CGPoint offsets;
/// Minimum size of container view. Default is CGSizeZero.
@property(assign, nonatomic) CGSize minimumSize;
/// The insets of views in content view bounds. Default is {15.0f, 15.0f, 15.0f, 15.0f}
@property(assign, nonatomic) UIEdgeInsets contentInsets;
#pragma mark - Time interval.
/// Grace time showing hud view. Default is 0.0f.
@property(assign, nonatomic) NSTimeInterval grace;
/// Minimum showing time interval of hud view. Default is 0.5f.
@property(assign, nonatomic) NSTimeInterval threshold;
#pragma mark - Mode and ENUM.
/// Mode of the hud view..
@property(assign, nonatomic) AXPracticalHUDMode mode;
/// Animation style of hud view. Default is .Fade.
@property(assign, nonatomic) AXPracticalHUDAnimation animation;
/// Position of the hud view.
@property(assign, nonatomic) AXPracticalHUDPosition position;
/// Completion block when hud view has hidden.
@property(copy, nonatomic) AXPracticalHUDCompletionBlock completion;
#pragma mark - Tasks.
/// Is tasks progressing.
@property(readonly, nonatomic) BOOL progressing;
#pragma mark - Progress.
/// Progress of the progerss indicator.
@property(assign, nonatomic) CGFloat progress;
#pragma mark - Custom view.
/// Custom view. Readwrite.
@property(strong, nonatomic) UIView *customView;
#pragma mark - Content view
/// Content view.
@property(readonly, strong, nonatomic) AXPracticalHUDContentView *contentView;
#pragma mark - Label
/// Title label.
@property(readonly, strong, nonatomic) UILabel *label;
#pragma mark - Detail label.
/// Detail label.
@property(readonly, strong, nonatomic) UILabel *detailLabel;
#pragma mark - Initializer
- (instancetype)initWithView:(UIView *)view;
- (instancetype)initWithWindow:(UIWindow *)window;
#pragma mark - Show & Hide.
- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)show:(BOOL)animated executingBlock:(dispatch_block_t)executing onQueue:(dispatch_queue_t)queue completion:(AXPracticalHUDCompletionBlock)completion;
- (void)show:(BOOL)animated executingBlockOnGQ:(dispatch_block_t)executing completion:(AXPracticalHUDCompletionBlock)completion;
- (void)show:(BOOL)animated executingMethod:(SEL)method toTarget:(id)target withObject:(id)object;

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay completion:(AXPracticalHUDCompletionBlock)completion;
@end

@interface AXPracticalHUD(Shared)
+ (instancetype)sharedHUD;

- (void)showPieInView:(UIView *)view;
- (void)showProgressInView:(UIView *)view;
- (void)showColorfulProgressInView:(UIView *)view;
- (void)showTextInView:(UIView *)view;
- (void)showSimpleInView:(UIView *)view;
- (void)showErrorInView:(UIView *)view;
- (void)showSuccessInView:(UIView *)view;

- (void)showPieInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showProgressInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showColorfulProgressInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showTextInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showSimpleInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showErrorInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
- (void)showSuccessInView:(UIView *)view text:(NSString *)text detail:(NSString *)detail configuration:(void(^)(AXPracticalHUD *HUD))configuration;
@end

@interface AXPracticalHUD(Convenence)
+ (instancetype)showHUDInView:(UIView *)view animated:(BOOL)animated;
+ (BOOL)hideHUDInView:(UIView *)view animated:(BOOL)animated;
+ (NSInteger)hideAllHUDsInView:(UIView *)view animated:(BOOL)animated;
+ (instancetype)HUDInView:(UIView *)view;
+ (NSArray *)HUDsInView:(UIView *)view;
@end

@protocol AXPracticalHUDDelegate <NSObject>
@optional
- (void)HUDDidHidden:(AXPracticalHUD *)HUD;
@end
