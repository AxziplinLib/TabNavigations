//
//  AXViewControllerShema.h
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

#ifndef kAXResponderSchemaManager
#define kAXResponderSchemaManager [AXResponderSchemaManager sharedManager]
#endif

NS_ASSUME_NONNULL_BEGIN
/// Module defined as `viewcontroller`.
extern NSString *const kAXResponderSchemaModuleUIViewController;
/// Module defined as `control`.
extern NSString *const kAXResponderSchemaModuleUIControl;
/// Default schema identifiers for UITabBarController.
extern NSString *const kAXResponderSchemaTabBarControllerIdentifier;

@interface AXResponderSchemaManager : NSObject
/// App schema.
@property(copy, nonatomic) NSString *appSchema;
/// Class for navigation controller.
@property(nullable, copy, nonatomic) Class navigationControllerClass;
/// View controller to show the new added view controller.
@property(nullable, weak, nonatomic) UIViewController *viewController;
/// Tab bar controller to show selectd view controller.
@property(nullable, weak, nonatomic) UITabBarController *tabBarController;
/// Navigation controller to push new added view controller.
@property(nullable, weak, nonatomic) UINavigationController *navigationController;
/// Get the shared instance.
///
/// @result return the shared instance.
+ (instancetype)sharedManager;
/// Register a class identifier for a specific schema identifier.
///
/// @param schemaIdentifier schema identifier to be registered.
/// @param class  class for the schema.
///
+ (void)registerSchema:(NSString *)schemaIdentifier forClass:(Class)class;
- (void)registerSchema:(NSString *)schemaIdentifier forClass:(Class)class;
+ (void)registerClass:(Class)class;
- (void)registerClass:(Class)class;
/// Unregister the class identifier for the specific schema identifier and remove the configuration.
///
/// @param schemaIdentifier schema identifier to be unregistered.
+ (void)unregisterSchema:(NSString *)schemaIdentifier;
- (void)unregisterSchema:(NSString *)schemaIdentifier;
/// Get the class of the schema identifier.
///
/// @discusstion The manager will check from the view controller fisrt (UIViewController+Schema) to get the class.
///              If the class from view controller is NULL, then manager will get the class from the configuration
///              location.
///
/// @param schemaIdentifier schema identifier registered.
///
/// @return Class for the schema. Can be NULL.
+ (Class _Nullable)classForSchema:(NSString *)schemaIdentifier;
- (Class _Nullable)classForSchema:(NSString *)schemaIdentifier;
/// Open url.
///
/// @param url url to be opened.
///
/// @return result value.
- (BOOL)openURL:(NSURL *)url;
/// Open the url with custom completion schema.
///
/// @param url url to open.
/// @param completion schema for custom completion schema.
///
/// @return result value.
- (BOOL)openURL:(NSURL *)url completion:(NSURL *_Nullable)completion;
/// Open the url with custom completion schema.
///
/// @param url url to open.
/// @param viewDidAppear schema for view did appear schema.
///
/// @return result value.
- (BOOL)openURL:(NSURL *)url viewDidAppear:(NSURL*_Nullable)viewDidAppear;
/// Open the url with custom completion schema.
///
/// @param url url to open.
/// @param completion schema for custom completion schema.
/// @param viewDidAppear schema for view did appear schema.
///
/// @return result value.
- (BOOL)openURL:(NSURL *)url completion:(NSURL *_Nullable)completion viewDidAppear:(NSURL*_Nullable)viewDidAppear;
/// Can open the url.
///
/// @discusstion If scheme is not app schema, return the application shared instance's result.
///
/// @param url url to open.
///
/// @return result value.
- (BOOL)canOpenURL:(NSURL *)url;
@end
NS_ASSUME_NONNULL_END
