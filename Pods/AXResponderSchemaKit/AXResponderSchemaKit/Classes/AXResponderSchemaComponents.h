//
//  AXSchemaComponents.h
//  AXViewControllerShema
//
//  Created by devedbox on 2016/10/11.
//  Copyright © 2016年 devedbox. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 * appname://viewcontroller/login?navigation=1&animated=1
 * appname://viewcontroller/login/navigation/1/animated/1
 * appname://viewcontroller/tabbar?selectedindex=1
 * appname://viewcontroller/tabbar/selectedindex/1
 * appname://control/like?action=64
 * appname://control/like/action/64
 */
NS_ASSUME_NONNULL_BEGIN
/// Param key: `navigation`
///
/// @description Navigation type using push or present.
extern NSString *const kAXResponderSchemaNavigationKey;
/// Param key: `animated`
///
/// @description Animate to show view controller. Default is YES.
extern NSString *const kAXResponderSchemaAnimatedKey;
/// Param key: `selectedindex`
///
/// @description Selected index for tab bar controller.
extern NSString *const kAXResponderSchemaSelectedIndexKey;
/// Param key: `action`
///
/// @description UIControlEvents for `UIControl`.
extern NSString *const kAXResponderSchemaActionKey;
/// Param key: `class`
///
/// @description Class name for view controller.
extern NSString *const kAXResponderSchemaSchemaClassKey;
/// Param key: `force`
///
/// @description Force to show view controller ignoring existed view controller. Default is NO.
extern NSString *const kAXResponderSchemaForceKey;
/// Param key: `delay`
///
/// @description Timeinterval duration to show view controller.
extern NSString *const kAXResponderSchemaDelayKey;

typedef NS_ENUM(int64_t, AXSchemaNavigation) {
    /// Push view controllers using navigation controller.
    AXSchemaNavigationPush,
    /// Present view controllers using view controller.
    AXSchemaNavigationPresent,
    /// Select view controllers using tab bar view controllers.
    AXSchemaNavigationSelectedIndex
};

@interface AXResponderSchemaComponents : NSObject
/// Scheme of the manager.
@property(nullable, readonly, nonatomic) NSString *scheme;
/// Moudle of manager to handle with.
@property(nullable, readonly, nonatomic) NSString *module;
/// Class of the module.
@property(nullable, readonly, nonatomic) NSString *identifier;
/// Class of schema.
@property(nullable, readonly, nonatomic) NSString *schemaClassIdentifier;
/// Navigation type for `viewcontroller` module.
@property(readonly, nonatomic) AXSchemaNavigation navigation;
/// Events type for `control` module.
@property(readonly, nonatomic) UIControlEvents event;
/// Animated for the `viewcontroller` module.
@property(readonly, nonatomic) BOOL animated;
/// Selected index for `UITabBarController` schema.
@property(readonly, nonatomic) NSInteger selectedIndex;
/// Force to show view controller.
@property(readonly, nonatomic) BOOL force;
/// Delay time duration of schema.
@property(readonly, nonatomic) NSTimeInterval delay;
/// Params of url.
@property(readonly, strong, nonatomic) NSDictionary *params;
/// URL.
@property(readonly, nonatomic) NSURL *URL;

- (instancetype)initWithURL:(NSURL *)url;
+ (instancetype)componentsWithURL:(NSURL *)url;

@end
NS_ASSUME_NONNULL_END
