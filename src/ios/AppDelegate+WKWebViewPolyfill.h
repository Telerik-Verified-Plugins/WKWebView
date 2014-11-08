#import <objc/runtime.h>
#import <Cordova/CDVPlugin.h>

@class HTTPServer;
HTTPServer *httpServer;

@interface AppDelegate (WKWebViewPolyfill)
@end

@interface WKWebViewPolyfill : CDVPlugin
@end
