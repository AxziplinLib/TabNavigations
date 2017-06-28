//
//  UIAlertController+Schema.m
//  AXResponderSchemaManager
//
//  Created by devedbox on 2016/10/13.
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

#import "UIAlertController+Schema.h"
#import "AXResponderSchemaConstant.h"
#import "AXResponderSchemaComponents.h"

NSString *const kAXResponderSchemaAlertSchemaTitleKey = @"title";
NSString *const kAXResponderSchemaAlertSchemaMessageKey = @"message";
NSString *const kAXResponderSchemaAlertSchemaStyleKey = @"style";
NSString *const kAXResponderSchemaAlertSchemaButtonTitleKey = @"button";

@implementation UIAlertController(Schema)
+ (nullable instancetype)viewControllerForSchemaWithParams:(NSDictionary **)params {
    NSString *title = (*params)[kAXResponderSchemaAlertSchemaTitleKey];
    NSString *message = (*params)[kAXResponderSchemaAlertSchemaMessageKey];
    NSString *button = (*params)[kAXResponderSchemaAlertSchemaButtonTitleKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0) {
        title = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        message = [message stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        button = [button stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        title = [title stringByRemovingPercentEncoding];
        message = [message stringByRemovingPercentEncoding];
        button = [button stringByRemovingPercentEncoding];
    }
#pragma clang diagnostic pop
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(*params)[kAXResponderSchemaAlertSchemaStyleKey]?[(*params)[kAXResponderSchemaAlertSchemaStyleKey] integerValue]:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:button?:AXResponderSchemaManagerLocalizedString(@"confirm", @"Confirm") style:UIAlertActionStyleCancel handler:NULL]];
    if ((*params)[kAXResponderSchemaNavigationKey]) {
        AXSchemaNavigation navigation = [(*params)[kAXResponderSchemaNavigationKey] integerValue];
        if (navigation != AXSchemaNavigationPresent) {
            NSMutableDictionary *dic = [(*params) mutableCopy];
            dic[kAXResponderSchemaNavigationKey] = @"1";
            (*params) = dic;
        }
    } else {
        NSMutableDictionary *dic = [(*params) mutableCopy];
        dic[kAXResponderSchemaNavigationKey] = @"1";
        (*params) = dic;
    }
    return alert;
}

+ (nullable Class)classForSchemaIdentifier:(NSString *_Nonnull)schemaIdentifier {
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'alert'"] evaluateWithObject:schemaIdentifier]) {
        return self.class;
    }
    return [super classForSchemaIdentifier:schemaIdentifier];
}
@end
