#import <Foundation/Foundation.h>
#import "ReroutingUIWebView.h"

// note that this is not the most elegant solution, but as a pragmatic fix it works nicely for my usecases
@implementation ReroutingUIWebView

// because plugins send their result to the UIWebView, this method reroutes this data to the WKWebView
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
  [self.wkWebView evaluateJavaScript:script completionHandler:nil];
  return nil;
}

// Ionic's Keyboard Plugin 'close()' function uses this
- (BOOL)endEditing:(BOOL)force {
  return [self.wkWebView endEditing:force];
}

// the Toast plugin (for one) adds a subview to the webview which needs to propagate to the wkwebview
- (void)addSubview:(UIView *)view {
  [self.wkWebView addSubview:view];
}

@end