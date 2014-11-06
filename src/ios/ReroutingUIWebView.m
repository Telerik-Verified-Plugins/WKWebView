#import <Foundation/Foundation.h>
#import "ReroutingUIWebView.h"

@implementation ReroutingUIWebView

// because plugins send their result to the UIWebView, this method reroutes this data to the WKWebView
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
  [self.wkWebView evaluateJavaScript:script completionHandler:nil];
  return nil;
}

@end