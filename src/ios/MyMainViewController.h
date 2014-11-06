#import "MainViewController.h"
#import "CDVWebViewOperationsDelegate.h"
#import <WebKit/WebKit.h>
#import <WebKit/WKWebView.h>

@interface MyMainViewController : MainViewController <WKScriptMessageHandler> {
  @protected CDVWebViewOperationsDelegate* _webViewOperationsDelegate;
}

@property (nonatomic, strong) IBOutlet UIWebView* webView;
@property (nonatomic, strong) IBOutlet WKWebView* wkWebView;
@end