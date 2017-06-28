//
//  UIViewController+Schema.m
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

#import "UIViewController+Schema.h"
#import "AXResponderSchemaManager.h"
#import <objc/runtime.h>

static NSArray *subclasses;

@implementation UIViewController (Schema)

+ (void)ax_exchangeClassOriginalMethod:(SEL)original swizzledMethod:(SEL)swizzled {
    Method _method1 = class_getInstanceMethod(self, original);
    if (_method1 == NULL) return;
    method_exchangeImplementations(_method1, class_getClassMethod(self, swizzled));
}

+ (void)ax_exchangeInstanceOriginalMethod:(SEL)original swizzledMethod:(SEL)swizzled {
    Method _method1 = class_getInstanceMethod(self, original);
    if (_method1 == NULL) return;
    method_exchangeImplementations(_method1, class_getInstanceMethod(self, swizzled));
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self ax_exchangeInstanceOriginalMethod:@selector(viewDidAppear:) swizzledMethod:@selector(ax_viewDidAppear:)];
    });
    // Get all sub classes.
    // Classes buffer.
    Class *classes;
    // Get the count of all class.
    int count = objc_getClassList(NULL, 0);
    
    NSMutableArray *subclses = [NSMutableArray array];
    
    if (count > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * count);
        count = objc_getClassList(classes, count);
        for (int i = 0; i < count; i ++) {
            @autoreleasepool {
                Class cls = classes[i];
                Class superClass = cls;
                while (superClass!=NULL && !class_isMetaClass(superClass)) {
                    superClass = class_getSuperclass(superClass);
                    if (superClass == UIViewController.class) {
                        [subclses addObject:cls];
                        superClass = NULL;
                    }
                }
            }
        }
        subclasses = [subclses copy];
        free(classes);
    }
}

+ (instancetype)viewControllerForSchemaWithParams:(NSDictionary **)params {
    return nil;
}

- (BOOL)shouldResolveSchemaWithParams:(NSDictionary *)params {
    return YES;
}

- (void)resolveSchemaWithParams:(NSDictionary *)params {
}

- (void)resolveSchemaWithURL:(NSURL *)URL {
}

+ (Class)classForNavigationController {
    return UINavigationController.class;
}

+ (Class)classForSchemaIdentifier:(NSString *)schemaIdentifier {
    Class matchedCls = NULL;
    for (Class cls in subclasses) {
        Class superClass = class_getSuperclass(cls);
        if (superClass == self.class) {
            Class _cls = [cls classForSchemaIdentifier:schemaIdentifier];
            if (_cls != NULL) {
                matchedCls = _cls;
                break;
            }
        }
    }
    
    if (matchedCls != NULL) {
        NSMutableArray *classes = [subclasses mutableCopy];
        [classes removeObject:matchedCls];
        // Move the matchd calss to the top of the classes.
        [classes insertObject:matchedCls atIndex:0];
        subclasses = [classes copy];
        
        return matchedCls;
    }
    
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] %@", NSStringFromClass(self.class)] evaluateWithObject:schemaIdentifier]) {
        return self.class;
    }
    return NULL;
}

+ (BOOL)allowsForSchameIdentifier:(NSString *)schemaIdentifier {
    return YES;
}

- (void)ax_viewDidAppear:(BOOL)animated {
    [self ax_viewDidAppear:animated];
    if (self.viewDidAppearSchema) {
        [[AXResponderSchemaManager sharedManager] openURL:self.viewDidAppearSchema];
        self.viewDidAppearSchema = nil;
    }
}

- (UIControl *)UIControlOfViewControllerForIdentifier:(NSString *)controlIdentifier {
    return nil;
}

- (NSURL *)viewDidAppearSchema {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setViewDidAppearSchema:(NSURL *)viewDidAppearSchema {
    objc_setAssociatedObject(self, @selector(viewDidAppearSchema), viewDidAppearSchema, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
