//
//  UIAlertController+Schema.h
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

#import <UIKit/UIKit.h>
#import "UIViewController+Schema.h"

/// Alert title key: `title`.
extern NSString *_Nonnull const kAXResponderSchemaAlertSchemaTitleKey;
/// Alert message key: `message`.
extern NSString *_Nonnull const kAXResponderSchemaAlertSchemaMessageKey;
/// Alert style key: `style`.
extern NSString *_Nonnull const kAXResponderSchemaAlertSchemaStyleKey;
/// Alert button title key: `button`.
extern NSString *_Nonnull const kAXResponderSchemaAlertSchemaButtonTitleKey;

@interface UIAlertController (Schema)
/// Convenient method to create a alert view controller with a parameter with the key-values from above.
///
/// @param params params to create alert view controller with.
///
+ (nullable instancetype)viewControllerForSchemaWithParams:(NSDictionary *_Nullable*_Nullable)params;
/// Override the class getting and return a class to be referenced for the schema url.
///
/// @param schemaIdentifier a schema identifier to be compared with. In this case, it would be `alert`.
///
+ (nullable Class)classForSchemaIdentifier:(NSString *_Nonnull)schemaIdentifier;
@end
