#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIView+ChainAnimator.h"
#import "AXChainAnimator.h"
#import "CALayer+AnchorPoint.h"
#import "AXCoreAnimation.h"
#import "AXDecayAnimation.h"
#import "AXSpringAnimation.h"
#import "CAAnimation+Convertable.h"
#import "CAAnimation+ImmediateValue.h"
#import "CAMediaTimingFunction+Extends.h"

FOUNDATION_EXPORT double AXAnimationChainSwiftVersionNumber;
FOUNDATION_EXPORT const unsigned char AXAnimationChainSwiftVersionString[];

