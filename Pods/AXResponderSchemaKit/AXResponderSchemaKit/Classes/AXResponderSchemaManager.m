//
//  AXViewControllerShema.m
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

#import "AXResponderSchemaManager.h"
#import "AXResponderSchemaConstant.h"
#import "AXResponderSchemaComponents.h"
#import "UIViewController+Schema.h"
#import <objc/runtime.h>

NSString *const kAXResponderSchemaModuleUIViewController = @"viewcontroller";
NSString *const kAXResponderSchemaModuleUIControl = @"control";

NSString *const kAXResponderSchemaTabBarControllerIdentifier = @"tabbar";

NSString *const kAXResponderSchemaCompletionURLKey = @"completion";

@interface UIViewController (TopPresentedViewController)
/// Top presented view controller.
@property(readonly, nonatomic, nullable) UIViewController *topPresentedViewController;
@end

@implementation AXResponderSchemaManager
+ (instancetype)sharedManager {
    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Public
- (BOOL)canOpenURL:(NSURL *)url {
    return [self _canOpenURL:url]?:[[UIApplication sharedApplication] canOpenURL:url];;
}

- (BOOL)openURL:(NSURL *)url {
    return [self openURL:url completion:nil viewDidAppear:nil];
}

- (BOOL)openURL:(NSURL *)url completion:(NSURL *)completion {
    return [self openURL:url completion:completion viewDidAppear:nil];
}

- (BOOL)openURL:(NSURL *)url viewDidAppear:(NSURL *)viewDidAppear {
    return [self openURL:url completion:nil viewDidAppear:viewDidAppear];
}

- (BOOL)openURL:(NSURL *)url completion:(NSURL *)completion viewDidAppear:(NSURL *)viewDidAppear {
    if (![self canOpenURL:url]) return NO;
    if (![self _canOpenURL:url]) {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_9_4) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:NULL];
                return YES;
            } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                return [[UIApplication sharedApplication] openURL:url];
#pragma clang diagnostic pop
            }
        }
    }
    
    return [self _openSchemaWithSchemaComponents:[AXResponderSchemaComponents componentsWithURL:url] completion:completion viewDidAppearSchema:viewDidAppear];
}

+ (void)registerSchema:(NSString *)schemaIdentifier forClass:(Class)class {
    if ([self classForSchema:schemaIdentifier] != NULL) return;
    
    Class supcls = class;
    BOOL shouldRegisterTheClass = NO;
    while (supcls != NULL && !class_isMetaClass(supcls)) {
        supcls = class_getSuperclass(supcls);
        if (supcls == UIViewController.class) {
            shouldRegisterTheClass = YES; break;
        }
    }
    
    NSAssert(shouldRegisterTheClass, @"The class to be registered must be the subclass of the UIViewController.");
    
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromClass(class) forKey:[NSString stringWithFormat:@"_axresponderschema_%@", schemaIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)registerSchema:(NSString *)schemaIdentifier forClass:(Class)class {
    [self.class registerSchema:schemaIdentifier forClass:class];
}

+ (void)registerClass:(Class)class {
    [self registerSchema:NSStringFromClass(class) forClass:class];
}

- (void)registerClass:(Class)class {
    [self.class registerClass:class];
}

+ (void)unregisterSchema:(NSString *)schemaIdentifier {
    if ([self classForSchema:schemaIdentifier] == NULL) return;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:[NSString stringWithFormat:@"_axresponderschema_%@", schemaIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)unregisterSchema:(NSString *)schemaIdentifier {
    [self.class unregisterSchema:schemaIdentifier];
}

+ (Class)classForSchema:(NSString *)schemaIdentifier {
    NSString *classIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"_axresponderschema_%@", schemaIdentifier]];
    return NSClassFromString(classIdentifier);
}

- (Class)classForSchema:(NSString *)schemaIdentifier {
    return [self.class classForSchema:schemaIdentifier];
}
#pragma mark - Private
- (BOOL)_canOpenURL:(NSURL *)url {
    if (!url) return NO;
    return [self _isAppSchema:[AXResponderSchemaComponents componentsWithURL:url]];
}

- (BOOL)_isAppSchema:(AXResponderSchemaComponents *)schema {
    return [[schema scheme] isEqualToString:_appSchema?:[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] lowercaseString]];
}

- (BOOL)_openSchemaWithSchemaComponents:(AXResponderSchemaComponents *)components completion:(NSURL *)completionURL viewDidAppearSchema:(NSURL *)schema {
    // Find class for schema in the registered classes first.
    Class schemaClass = [self.class classForSchema:components.identifier];
    // Class is not registered. Find using runtime.
    if (schemaClass == NULL) {
        if (components.schemaClassIdentifier.length > 0) {// Get the specific class for class identifier in url params.
            schemaClass = [UIViewController classForSchemaIdentifier:components.schemaClassIdentifier];
            if (schemaClass == NULL) {// Get the class for the schema identifier.
                schemaClass = [UIViewController classForSchemaIdentifier:components.identifier];
            }
        } else {// Get the class for the schema identifier.
            schemaClass = [UIViewController classForSchemaIdentifier:components.identifier];
        }
    }
    // Return NO if class for schema is null.
    if (schemaClass == NULL) return NO;
    // Return NO if class for schema is meta class.
    if (class_isMetaClass(schemaClass)) return NO;
    // Return NO if class for schema does not allow the schema.
    if (![schemaClass allowsForSchameIdentifier:components.identifier]) return NO;
    
    if ((![UIApplication sharedApplication].keyWindow.rootViewController) && ![components.identifier isEqualToString:kAXResponderSchemaTabBarControllerIdentifier]) return NO;
    
    void(^_ALERT_ISSUE)() = ^() {
        // Show the alert.
        [components setValue:@"alert" forKeyPath:@"identifier"];
        // Set title.
        NSString *title = AXResponderSchemaManagerLocalizedString(@"openfailed", @"Openfailed");
        // Set message.
        NSString *message = AXResponderSchemaManagerLocalizedString(@"openissue", @"Openissue");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0) {
            title = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            message = [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
        } else {
            NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
            NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
            title = [title stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
            message = [message stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        }
#pragma clang diagnostic pop
        // Open alert controller.
        [self openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://viewcontroller/alert?title=%@&message=%@", components.scheme, title, message]]];
    };
    
    // Handle the moudles.
    if ([components.module isEqualToString:kAXResponderSchemaModuleUIViewController]) { // View controller -> Show and hide.
        // Do not open if the class for the schema is not the subclass of the UIViewController.
        if (![schemaClass isSubclassOfClass:UIViewController.class]) {
            return NO;
        }
        // Force to show(push/present e.g.) the view controller. Default is no force.
        BOOL force = NO;
        if (components.params[kAXResponderSchemaForceKey]) {
            force = components.force;
        }
        // If the instance of the class for schema is already exiting and no force, return YES.
        if ([[self _topViewController] isMemberOfClass:schemaClass] && !force) return YES;
        
        // Set up params.
        NSMutableDictionary *params = [components.params mutableCopy];
        if (completionURL) [params setObject:completionURL forKey:kAXResponderSchemaCompletionURLKey];
        // Get the view controller instance of the class for the schema with the params of the schema. This gave the chance to handle the params of the schema.
        UIViewController *viewController = [schemaClass viewControllerForSchemaWithParams:&params];
        // This gave a chance for the instance of the class for the schema to deal with the original url.
        [viewController resolveSchemaWithURL:components.URL];
        // Update the params of the compnents of url.
        [components setValue:params forKeyPath:@"params"];
        // Set the view-did-appear schema to the nonalert view controller.
        if (![viewController isMemberOfClass:UIAlertController.class]) {
            viewController.viewDidAppearSchema = schema;
        }
        
        UIViewController *viewControllerToShowOf = _navigationController?:_viewController;
        // Animated to show view controller. Default is YES.
        BOOL animated = YES;
        if (components.params[kAXResponderSchemaAnimatedKey]) {
            animated = components.animated;
        }
        
        // Get the navitation.
        switch (components.navigation) {
            case AXSchemaNavigationPresent: {
                // Get the top view controller of the application.
                UIViewController *topViewController = [self _topViewController];
                // Handle openning view controller without force.
                if (!force) {
                    // Should resolve the schema, default is YES.
                    BOOL shouldResolveSchema=YES;
                    // Handle with top view controller.
                    if ([topViewController isMemberOfClass:schemaClass]) { // Top view controller is an instance of the class for the schema.
                        // Make the top view controller resolve the original url.
                        [topViewController resolveSchemaWithURL:components.URL];
                        // Get flag to resolve the schema with params of the schema.
                        shouldResolveSchema = [topViewController shouldResolveSchemaWithParams:components.params];
                        // If should resolve schema, resolve the schema with params and return YES since the top view controller is an instance of the class for the schema and without force.
                        if (shouldResolveSchema) {
                            // Call the resolve method to resolve the schema with params.
                            [topViewController resolveSchemaWithParams:components.params];
                            return YES;
                        } else return NO;
                    } if ([topViewController isKindOfClass:[UINavigationController class]]) { // Class of top view controller is kind of UINavigationController.
                        // Get the navigation controller.
                        UINavigationController *navigationController = (UINavigationController *)topViewController;
                        if ([navigationController.topViewController isMemberOfClass:schemaClass]) {
                            
                            [navigationController.topViewController resolveSchemaWithURL:components.URL];
                            shouldResolveSchema = [navigationController.topViewController shouldResolveSchemaWithParams:components.params];
                            
                            if (shouldResolveSchema) {
                                [navigationController.topViewController resolveSchemaWithParams:components.params];
                                return YES;
                            } else return NO;
                        }
                    } if (topViewController.topPresentedViewController) {
                        // Get top presented view controller.
                        UIViewController *presentedViewController = topViewController.topPresentedViewController;
                        
                        if ([presentedViewController isMemberOfClass:schemaClass]) {
                            
                            [presentedViewController resolveSchemaWithURL:components.URL];
                            shouldResolveSchema = [presentedViewController shouldResolveSchemaWithParams:components.params];
                            
                            if (shouldResolveSchema) {
                                [presentedViewController resolveSchemaWithParams:components.params];
                                return YES;
                            } else return NO;
                        } if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
                            // Get the navigation controller.
                            UINavigationController *navigationController = (UINavigationController *)presentedViewController;
                            if ([navigationController.topViewController isMemberOfClass:schemaClass]) {
                                
                                [navigationController.topViewController resolveSchemaWithURL:components.URL];
                                shouldResolveSchema = [navigationController.topViewController shouldResolveSchemaWithParams:components.params];
                                
                                if (shouldResolveSchema) {
                                    [navigationController.topViewController resolveSchemaWithParams:components.params];
                                    return YES;
                                } else return NO;
                            }
                        }
                    } if ([topViewController presentingViewController]) {
                        // Get the presenting view controller.
                        UIViewController *presentingViewController = topViewController.presentingViewController;
                        
                        if ([presentingViewController isMemberOfClass:schemaClass]) {
                            
                            [presentingViewController resolveSchemaWithURL:components.URL];
                            shouldResolveSchema = [presentingViewController shouldResolveSchemaWithParams:components.params];
                            
                            if (shouldResolveSchema) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    [topViewController dismissViewControllerAnimated:animated completion:NULL];
                                });
                                [presentingViewController resolveSchemaWithParams:components.params];
                                return YES;
                            } else return NO;
                        } if ([presentingViewController isKindOfClass:[UINavigationController class]]) {
                            // Get the navigation controller.
                            UINavigationController *navigationController = (UINavigationController *)presentingViewController;
                            if ([navigationController.topViewController isMemberOfClass:schemaClass]) {
                                
                                [navigationController.topViewController resolveSchemaWithURL:components.URL];
                                shouldResolveSchema = [navigationController.topViewController shouldResolveSchemaWithParams:components.params];
                                
                                if (shouldResolveSchema) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        [topViewController dismissViewControllerAnimated:animated completion:NULL];
                                    });
                                    [navigationController.topViewController resolveSchemaWithParams:components.params];
                                    return YES;
                                } else return NO;
                            }
                        }
                    }
                }
                // If with force or no instance without force.
                
                // Show the alert if none of view controller.
                if (!viewController) {
                    _ALERT_ISSUE(); return NO;
                }
                
                [viewController resolveSchemaWithURL:components.URL];
                BOOL shouldResloveSchema = [viewController shouldResolveSchemaWithParams:components.params];
                if (shouldResloveSchema) {
                    [viewController resolveSchemaWithParams:components.params];
                } else return NO;
                
                // If none of view controller to show of, then set with the top view controller.
                if (!viewControllerToShowOf) {
                    viewControllerToShowOf = topViewController;
                }
                
                if ([viewController isKindOfClass:UINavigationController.class] || [viewController isKindOfClass:UIAlertController.class]) { // Presented with nagigation controller.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [viewControllerToShowOf presentViewController:viewController animated:animated completion:NULL];
                    });
                } else {
                    // Get navigation controller class.
                    Class navigationControllerClass = class_respondsToSelector(schemaClass, @selector(classForNavigationController))?[schemaClass classForNavigationController]:_navigationControllerClass?:UINavigationController.class;
                    // Verify class.
                    if (class_isMetaClass(navigationControllerClass)) return NO;
                    if (![navigationControllerClass isSubclassOfClass:UINavigationController.class]) {
                        return NO;
                    }
                    // Initialize a navigation controller.
                    UINavigationController *navigationController = [[navigationControllerClass alloc] initWithRootViewController:viewController];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [viewControllerToShowOf presentViewController:navigationController animated:animated completion:NULL];
                    });
                }
                return YES;
            } break;
            case AXSchemaNavigationSelectedIndex: {
                // Get tab bar controller.
                UITabBarController *tabBarController;
                
                if ([viewController isKindOfClass:UITabBarController.class]) {
                    tabBarController = (UITabBarController *)viewController;
                } else {
                    tabBarController = _tabBarController;
                }
                
                if (!tabBarController) {
                    // Get the root view controller.
                    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                    if ([vc isKindOfClass:[UITabBarController class]]) {
                        tabBarController = (UITabBarController*)vc;
                    }
                }
                if (!tabBarController) {
                    _ALERT_ISSUE(); return NO;
                } else {
                    if (components.selectedIndex > tabBarController.viewControllers.count-1) {
                        return NO;
                    }
                    
                    [tabBarController resolveSchemaWithURL:components.URL];
                    BOOL shouldResolveSchema = [tabBarController shouldResolveSchemaWithParams:components.params];
                    
                    if (!shouldResolveSchema) {
                        return NO;
                    }
                    
                    [tabBarController resolveSchemaWithParams:components.params];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [tabBarController setSelectedIndex:components.selectedIndex];
                        
                        if ([[[tabBarController viewControllers] objectAtIndex:components.selectedIndex] isKindOfClass:[UINavigationController class]] && force) {
                            [(UINavigationController*)[[tabBarController viewControllers] objectAtIndex:components.selectedIndex] popToRootViewControllerAnimated:animated];
                        }
                    });
                }
                return YES;
            } break;
            default: {
                // Get the navigation controller.
                UINavigationController *navigationController = _navigationController ?: [self _rootNavigationController];
                
                if (!navigationController) {
                    _ALERT_ISSUE(); return NO;
                }
                
                if (force) {
                    if (!viewController) {
                        _ALERT_ISSUE(); return NO;
                    }
                    
                    [viewController resolveSchemaWithURL:components.URL];
                    if ([viewController shouldResolveSchemaWithParams:components.params]) {
                        [viewController resolveSchemaWithParams:components.params];
                    } else return NO;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [navigationController pushViewController:viewController animated:animated];
                    });
                    return YES;
                }
                
                UIViewController *exitsViewController;
                
                NSInteger index = [self _indexOfClass:schemaClass inNavigationController:&navigationController exists:&exitsViewController animated:animated];
                
                if (index == -1) { // Dismiss the presented view controller.
                    if (!exitsViewController) {
                        _ALERT_ISSUE(); return NO;
                    }
                    
                    [exitsViewController resolveSchemaWithURL:components.URL];
                    BOOL shouldResolveSchema = [exitsViewController shouldResolveSchemaWithParams:components.params];
                    if (shouldResolveSchema) {
                        [exitsViewController resolveSchemaWithParams:components.params];
                    } else return NO;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [navigationController dismissViewControllerAnimated:animated completion:NULL];
                    });
                } else if (index == NSNotFound) {
                    if (!viewController) {
                        _ALERT_ISSUE(); return NO;
                    }
                    
                    [viewController resolveSchemaWithURL:components.URL];
                    if ([viewController shouldResolveSchemaWithParams:components.params]) {
                        [viewController resolveSchemaWithParams:components.params];
                    } else return NO;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [navigationController pushViewController:viewController animated:animated];
                    });
                } else {
                    if (!exitsViewController) {
                        _ALERT_ISSUE(); return NO;
                    }
                    
                    [exitsViewController resolveSchemaWithURL:components.URL];
                    BOOL shouldResolveSchema = [exitsViewController shouldResolveSchemaWithParams:components.params];
                    if (shouldResolveSchema) {
                        [exitsViewController resolveSchemaWithParams:components.params];
                    } else return NO;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [navigationController popToViewController:navigationController.viewControllers[index] animated:animated];
                    });
                }
                return YES;
            } break;
        }
    } else if ([components.module isEqualToString:kAXResponderSchemaModuleUIControl]) { // UIControl -> Send actions.
        // Get the control object.
        if (![schemaClass isSubclassOfClass:UIViewController.class]) {
            return NO;
        }
        
        // Get the top view controller.
        UIViewController *topViewController = [self _topViewController];
        if (!topViewController) {
            _ALERT_ISSUE(); return NO;
        }
        
        if ([topViewController isMemberOfClass:schemaClass]) {
            // Resolve the params.
            [topViewController resolveSchemaWithURL:components.URL];
            if ([topViewController shouldResolveSchemaWithParams:components.params]) {
                [topViewController resolveSchemaWithParams:components.params];
            } else return NO;
            
            // Get control.
            UIControl *control = [topViewController UIControlOfViewControllerForIdentifier:components.identifier];
            if (!control) return NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(components.delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [control sendActionsForControlEvents:components.event];
            });
            return YES;
        } else {
            // Open view controller first.
            [components setValue:@"viewcontroller" forKeyPath:@"module"];
            NSMutableDictionary *params = [components.params mutableCopy];
            [params setObject:@(.0) forKey:@"delay"];
            [components setValue:[params copy] forKey:@"params"];
            return [self _openSchemaWithSchemaComponents:components completion:nil viewDidAppearSchema:components.URL];
        }
    }
    return NO;
}

#pragma mark - Private
- (UINavigationController *)_rootNavigationController {
    return [[self _topViewController] navigationController];
}

- (UIViewController *)_topViewController {
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self _topViewControllerWithRootViewController:topViewController];
}

- (UIViewController *)_topViewControllerWithRootViewController:(UIViewController *_Nullable)rootViewCoontroller {
    UIViewController *topViewController = rootViewCoontroller;
    // Find the view controller hierarchy if class is `UITabBarController`.
    if ([topViewController isKindOfClass:[UITabBarController class]]) {
        // Get the tab bar controller.
        UITabBarController *tabBarController = (UITabBarController *)topViewController;
        // Find the view controller hierarchy if class is still `UITabBarController` or `UINavigationController`.
        // Get the selected view controller of tabbar controller.
        UIViewController *selectedViewController = tabBarController.selectedViewController;
        if ([selectedViewController isKindOfClass:[UINavigationController class]] || [selectedViewController isKindOfClass:[UITabBarController class]]) {
            topViewController = [self _topViewControllerWithRootViewController:selectedViewController];
        }  else {
            // Get presented view controller.
            UIViewController *presentedViewController = selectedViewController.topPresentedViewController;
            
            if ([presentedViewController isKindOfClass:[UINavigationController class]] || [presentedViewController isKindOfClass:[UITabBarController class]]) {
                topViewController = [self _topViewControllerWithRootViewController:presentedViewController];
            } else {
                topViewController = presentedViewController?:selectedViewController;
            }
        }
    }
    // Resolve the navigation class.
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)topViewController;
        // Get presented view controller of navigation controller.
        UIViewController *presentedViewController = navigationController.topPresentedViewController;
        
        if (presentedViewController) {
            if ([presentedViewController isKindOfClass:[UINavigationController class]] || [presentedViewController isKindOfClass:[UITabBarController class]]) {
                return [self _topViewControllerWithRootViewController:navigationController.presentedViewController];
            }
            return presentedViewController;
        } else if (navigationController.topViewController) {
            presentedViewController = navigationController.topViewController.topPresentedViewController;
            
            if (presentedViewController) {
                if ([presentedViewController isKindOfClass:[UINavigationController class]] || [presentedViewController isKindOfClass:[UITabBarController class]]) {
                    return [self _topViewControllerWithRootViewController:presentedViewController];
                }
                return navigationController.topViewController.presentedViewController;
            } else {
                if ([navigationController.topViewController isKindOfClass:[UINavigationController class]] || [navigationController.topViewController isKindOfClass:[UITabBarController class]]) {
                    return [self _topViewControllerWithRootViewController:navigationController.topViewController];
                }
                return navigationController.topViewController;
            }
        } else {
            return navigationController;
        }
    } else if ([topViewController isKindOfClass:[UIViewController class]]) {
        // Get presented view controller of top view controller.
        UIViewController *presentedViewController = topViewController.topPresentedViewController;
        if (presentedViewController) {
            if ([presentedViewController isKindOfClass:[UINavigationController class]] || [topViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
                return [self _topViewControllerWithRootViewController:presentedViewController];
            }
            return presentedViewController;
        }
        return topViewController;
    } else {
        return topViewController;
    }
}

- (NSInteger)_indexOfClass:(Class)schemaClass inNavigationController:(UINavigationController **)navigationController exists:(UIViewController **)viewController animated:(BOOL)animated {
    // Find the index of schema class if exits.
    NSInteger index = [(*navigationController).viewControllers indexOfObjectPassingTest:^BOOL(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isMemberOfClass:schemaClass]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    if (index != NSNotFound) {
        (*viewController) = [(*navigationController).viewControllers objectAtIndex:index];
        return index;
    }
    if ((*navigationController).presentingViewController) {
        // Handle with presenting view controller.
        if ([(*navigationController).presentingViewController isMemberOfClass:schemaClass]) {
            // If current top view controller is member of schema class, return -1 to dismiss the presented controller.
            (*viewController) = (*navigationController).presentingViewController;
            return -1;
        } else if ([(*navigationController).presentingViewController isKindOfClass:UINavigationController.class]) {
            // Get navigation controller.
            UINavigationController *navi = (UINavigationController *)((*navigationController).presentingViewController);
            // Dismiss the navigation controller above.
            [(*navigationController) dismissViewControllerAnimated:animated completion:NULL];
            // Set the navigation controller blow.
            *navigationController = navi;
            // Call mthods again.
            return [self _indexOfClass:schemaClass inNavigationController:&navi exists:viewController animated:animated];
            // Handle with tab bar controller.
        } else if ([(*navigationController).presentingViewController isKindOfClass:UITabBarController.class]) {
            // Get tab bar controller.
            UITabBarController *tabBarController = (UITabBarController *)(*navigationController).presentingViewController;
            // Handle navigation controller if selected controller of tab bar controller is class of `UINavigationController`.
            if ([tabBarController.selectedViewController isKindOfClass:[UINavigationController class]]) {
                // Get the selected navigation controller.
                UINavigationController *navi = (UINavigationController *)tabBarController.selectedViewController;
                // Get the index of schema in the selected navigation controller.
                NSInteger index = [self _indexOfClass:schemaClass inNavigationController:&navi exists:viewController animated:animated];
                // Verify index of schema class.
                if (index != NSNotFound) {
                    // If index found, dismiss the navigation controller.
                    // Set to new.
                    (*navigationController) = navi;
                    // Dismiss.
                    [(*navigationController) dismissViewControllerAnimated:animated completion:NULL];
                }
                return index;
            }
        } else if ((*navigationController).presentingViewController.navigationController) {// Handle with the navigation controller of presenting controller.
            // Get the navigation controller.
            UINavigationController *navi = (*navigationController).presentingViewController.navigationController;
            // Dismiss the navigation controller.
            [(*navigationController) dismissViewControllerAnimated:animated completion:NULL];
            // Set the new.
            *navigationController = navi;
            // Call self.
            return [self _indexOfClass:schemaClass inNavigationController:&navi exists:viewController animated:animated];
        }
    }
    return NSNotFound;
}
@end

@implementation UIViewController (TopPresentedViewController)
- (UIViewController *)topPresentedViewController {
    UIViewController *presentedViewController = self.presentedViewController;
    
    while (presentedViewController.presentedViewController != nil) {
        presentedViewController = presentedViewController.presentedViewController;
    }
    
    return presentedViewController;
}
@end
