//
//  AXSchemaComponents.m
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

#import "AXResponderSchemaComponents.h"

@interface AXResponderSchemaComponents ()
/// Components.
@property(strong, nonatomic) NSURLComponents *components;
@end

NSString *const kAXResponderSchemaNavigationKey = @"navigation";
NSString *const kAXResponderSchemaAnimatedKey = @"animated";
NSString *const kAXResponderSchemaSelectedIndexKey = @"selectedindex";
NSString *const kAXResponderSchemaActionKey = @"action";
NSString *const kAXResponderSchemaSchemaClassKey = @"class";
NSString *const kAXResponderSchemaForceKey = @"force";
NSString *const kAXResponderSchemaDelayKey = @"delay";

@implementation AXResponderSchemaComponents
- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _URL = url;
        [self handleWithURL:url];
    }
    return self;
}

+ (instancetype)componentsWithURL:(NSURL *)url {
    // Alloc a instance of `AXSchemaComponents`.
    return [[self alloc] initWithURL:url];
}

#pragma mark - Getters
- (NSTimeInterval)delay {
    return MAX([_params[kAXResponderSchemaDelayKey] doubleValue], .0);
}

- (BOOL)force {
    return [_params[kAXResponderSchemaForceKey] boolValue];
}

- (NSString *)schemaClassIdentifier {
    return _params[kAXResponderSchemaSchemaClassKey];
}

- (AXSchemaNavigation)navigation {
    return [_params[kAXResponderSchemaNavigationKey] integerValue];
}

- (BOOL)animated {
    return [_params[kAXResponderSchemaAnimatedKey] boolValue];
}

- (UIControlEvents)event {
    return [_params[kAXResponderSchemaActionKey] integerValue];
}

- (NSInteger)selectedIndex {
    return [_params[kAXResponderSchemaSelectedIndexKey] integerValue];
}

#pragma mark - Private handler.
- (void)handleWithURL:(NSURL *)URL {
    // Initialize components of url.
    _components = [[NSURLComponents alloc] initWithString:URL.absoluteString];
    // Get the scheme of the url.
    _scheme = _components.scheme;
    // Get the module of url.
    _module = _components.host;
    // Get the query string.
    NSString *query = [_components query];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    if (query != nil) {
        // Handle query string and get the params.
        NSArray *comps = [query componentsSeparatedByString:@"&"];
        for (NSInteger i = 0; i < comps.count; i ++) {
            NSString *paramstr = comps[i];
            NSArray *paramcomps = [paramstr componentsSeparatedByString:@"="];
            NSString *key = [paramcomps firstObject];
            NSString *value = [paramcomps lastObject];
            param[key]=value;
        }
        _params = [param copy];
        // Get the scheme identifier.
        _identifier = [_components.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    } else {
        NSString *path = _components.path;
        NSArray *pathcomps = [[path componentsSeparatedByString:@"/"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
        if (pathcomps.count == 0) return;
        // Get the identifier in index 0.
        _identifier = [pathcomps firstObject];
        // Get the param comps.
        NSArray *paramcomps = [pathcomps subarrayWithRange:NSMakeRange(1, pathcomps.count-1)];
        if (paramcomps.count == 0) return;
        // Get the param dictionary.
        for (int i = 0; i < paramcomps.count; i += 2) {
            if (i>=paramcomps.count-1) {
                break;
            }
            NSString *key = paramcomps[i];
            NSString *value = paramcomps[i+1];
            param[key]=value;
        }
        _params = [param copy];
    }
}
@end
