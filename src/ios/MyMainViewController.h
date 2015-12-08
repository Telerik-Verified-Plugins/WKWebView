#import "MainViewController.h"
#import "CDVWebViewOperationsDelegate.h"
#import <WebKit/WebKit.h>
#import <WebKit/WKWebView.h>

@interface MyMainViewController : MainViewController <WKScriptMessageHandler, WKNavigationDelegate> {
  @protected CDVWebViewOperationsDelegate* _webViewOperationsDelegate;
}

@property (nonatomic, strong) IBOutlet WKWebView* wkWebView;

@property (nonatomic, readwrite, copy) NSString* uiWebViewLS;
@property (nonatomic, readwrite, copy) NSString* wkWebViewLS;
@property (nonatomic, readwrite, copy) NSString* docRoot;

@property (nonatomic, strong) NSURL* url;
@property (nonatomic, assign) BOOL pageLoaded;

@property (nonatomic, readwrite, assign) BOOL alreadyLoaded;
@property (nonatomic, assign) unsigned short port;

- (void)loadURL:(NSURL*)URL;
- (void)copyLS:(unsigned short)httpPort;
- (void)setServerPort:(unsigned short) port;
- (NSURL*)fixURL:(NSString*)URL;

@end
