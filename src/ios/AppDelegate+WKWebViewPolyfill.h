#import <objc/runtime.h>
#import <Cordova/CDVPlugin.h>

@interface AppDelegate (WKWebViewPolyfill)

@end

@interface WKWebViewPolyfill : CDVPlugin

- (void) loadFile:(CDVInvokedUrlCommand*)command;

@end
