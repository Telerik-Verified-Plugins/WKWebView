#import <Foundation/Foundation.h>
#import "ReroutingUIWebView.h"

// note that this is not the most elegant solution, but as a pragmatic fix it works nicely for my usecases
@implementation ReroutingUIWebView

@synthesize scrollView = _scrollView;

// Override the referenced scrollView to use WKWebView's scroll view, this helps fix plugins that alter
// the size of the UIScrollView (like the Keyboard Plugin)
- (void) setWkWebView:(WKWebView *)wkWebView{
    _scrollView = wkWebView.scrollView;
    _wkWebView = wkWebView;
}

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
- (void)layoutSubviews {
    self.wkWebView.frame = self.frame;
}

// Ionic's Deploy plugin uses this
- (void)loadRequest:(NSURLRequest*)request {
    [self.wkWebView loadRequest:request];
}

@end
