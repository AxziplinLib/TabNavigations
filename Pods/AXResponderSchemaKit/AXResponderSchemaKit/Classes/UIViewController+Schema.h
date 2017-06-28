//
//  UIViewController+Schema.h
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

#import <UIKit/UIKit.h>

/// URL key of completion key.
extern NSString *_Nonnull const kAXResponderSchemaCompletionURLKey;

@interface UIViewController (Schema)
/// View did appear urr schema.
@property(nullable, copy, nonatomic) NSURL *viewDidAppearSchema;
/// Get the view controller for responder schema.
///
/// @param params params of the url object.
///
/// @return a new view controller.
+ (nullable instancetype)viewControllerForSchemaWithParams:(NSDictionary *_Nullable*_Nullable)params;
#pragma mark - Handle the URL and params.
// resolve schema url -> should resolve schema params -YES> resolve schema params.

/// Dynamically handle the URL form a schema.
///
/// @param URL The URL to open.
///
- (void)resolveSchemaWithURL:(NSURL *_Nonnull)URL;
/// Get a value for the instance to handle params.
/// @discusstion If NO, the schema manager will perform a force schema instead.
///
/// @param params params of the url object.
///
- (BOOL)shouldResolveSchemaWithParams:(NSDictionary *_Nullable)params;
/// Dynamically handle the param form a schema.
///
/// @param params params of the url object.
///
- (void)resolveSchemaWithParams:(NSDictionary *_Nullable)params;
/// Get the class of navigation controller.
///
/// @return class of navigation controller.
+ (nullable Class)classForNavigationController;
/// Get the class for the schema identifier.
///
/// @discusstion You can custom the implementation of the method and return the class for a specific schema identifier.
///              Or you can do nothing be pass the string of view controller class to this method, and this method will
///              compare the schema identifier with the string from current class using `NSCaseInsensitiveSearch` option
///              to get the class identifier.
///
/// @param schemaIdentifier identifier of schema.
///
/// @return a class of view controller.
+ (nullable Class)classForSchemaIdentifier:(NSString *_Nonnull)schemaIdentifier;
/// Allows the be handled with a specfic schema identifier. Default is YES.
///
/// @param schemaIdentifier  identifier of schema.
///
/// @return a result to be allowed.
+ (BOOL)allowsForSchameIdentifier:(NSString *_Nonnull)schemaIdentifier;
/// Get the instance of view controller for the control identifier.
///
/// @param controlIdentifier a control identifier.
///
/// @return an instance of UIControl.
- (nullable __kindof UIControl *)UIControlOfViewControllerForIdentifier:(NSString *_Nullable)controlIdentifier;
@end
