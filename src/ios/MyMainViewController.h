#import "MainViewController.h"
#import "CDVWebViewOperationsDelegate.h"
#import <WebKit/WebKit.h>
#import <WebKit/WKWebView.h>

@interface MyMainViewController : MainViewController <WKScriptMessageHandler, WKNavigationDelegate> {
  @protected CDVWebViewOperationsDelegate* _webViewOperationsDelegate;
}

@property (nonatomic, strong) IBOutlet UIWebView* webView;
@property (nonatomic, strong) IBOutlet WKWebView* wkWebView;

@property (nonatomic, readwrite, copy) NSString* uiWebViewLS;
@property (nonatomic, readwrite, copy) NSString* wkWebViewLS;

@end