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

#import "AGGeometryKit.h"
#import "AGKBaseDefines.h"
#import "AGKBitOperations.h"
#import "AGKCorner.h"
#import "AGKLine.h"
#import "AGKMath.h"
#import "AGKQuad.h"
#import "AGKVector3D.h"
#import "AGGeometryKitCategories.h"
#import "AGKMatrix+AGKVector3D.h"
#import "AGKMatrix+CATransform3D.h"
#import "AGKMatrix+GLKit.h"
#import "CALayer+AGK+Methods.h"
#import "CALayer+AGK+Properties.h"
#import "CALayer+AGKQuad.h"
#import "NSValue+AGKQuad.h"
#import "UIBezierPath+AGKQuad.h"
#import "UIImage+AGK+CATransform3D.h"
#import "UIImage+AGKQuad.h"
#import "UIScrollView+AGK+Properties.h"
#import "UIView+AGK+AngleConverter.h"
#import "UIView+AGK+Properties.h"
#import "AGGeometryKitClasses.h"
#import "AGKCALayerAnimationBlockDelegate.h"
#import "AGKMatrix.h"
#import "AGKTransformPixelMapper.h"
#import "AGGeometryKitCoreGraphics.h"
#import "CGGeometry+AGGeometryKit.h"
#import "CGImageRef+AGK+CATransform3D.h"
#import "CALayer+AGK+Properties.h"
#import "UIView+AGK+Properties.h"

FOUNDATION_EXPORT double AGGeometryKitVersionNumber;
FOUNDATION_EXPORT const unsigned char AGGeometryKitVersionString[];

