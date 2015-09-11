#import "MyMainViewController.h"
#import <Cordova/CDVTimer.h>
#import <Cordova/CDVLocalStorage.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <Cordova/CDVWebViewDelegate.h>
#import <Cordova/CDVViewController.h>
#import <Cordova/CDVURLProtocol.h>
#import "CDVWebViewUIDelegate.h"
#import "ReroutingUIWebView.h"
#import "AppDelegate+WKWebViewPolyfill.h"

@interface CDVViewController ()
@property (nonatomic, readwrite, retain) NSArray *startupPluginNames;
@end

@interface MyMainViewController () {
  NSInteger _userAgentLockToken;
  CDVWebViewDelegate* _webViewDelegate;
  CDVWebViewUIDelegate* _webViewUIDelegate;
  BOOL _targetExistsLocally;
  NSTimer* _crashRecoveryTimer;
  BOOL _crashRecoveryActive;
  NSURL *_startURL;
}
@end

@implementation MyMainViewController

@synthesize alreadyLoaded;

- (id)init
{
  self = [super init];
  if (self) {
    // Save the path for our /www/ files
    NSURL* startURL = [NSURL URLWithString:self.startPage];
    NSString* startFilePath = [self.commandDelegate pathForResource:[startURL path]];
    _targetExistsLocally = [[NSFileManager defaultManager]
                             fileExistsAtPath:startFilePath];
    startFilePath = [startFilePath stringByDeletingLastPathComponent];
    self.wwwFolderName = startFilePath;
    self.alreadyLoaded = false;
  }

  if (![self settingForKey:@"DisableLocalStorageSyncWithUIWebView"] || ![[self settingForKey:@"DisableLocalStorageSyncWithUIWebView"] boolValue]) {
  // configure listeners which fires when the application goes away
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copyLocalStorageToUIWebView:)
                                               name:UIApplicationWillTerminateNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(copyLocalStorageToUIWebView:)
                                               name:UIApplicationWillResignActiveNotification object:nil];
  }

  // and some more for custom url schemes
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationLaunchedWithUrl:) name:CDVPluginHandleOpenURLNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationPageDidLoad:) name:CDVPageDidLoadNotification object:nil];

  return self;
}

- (void)applicationLaunchedWithUrl:(NSNotification*)notification {
  NSURL *url = [notification object];
  self.url = url;

  // warm-start handler
  if (self.pageLoaded) {
    [self processOpenUrl:self.url pageLoaded:YES];
    self.url = nil;
  }
}

- (void)applicationPageDidLoad:(NSNotification*)notification {
  // cold-start handler

  self.pageLoaded = YES;

  if (self.url) {
    [self processOpenUrl:self.url pageLoaded:YES];
    self.url = nil;
  }
}

- (void)processOpenUrl:(NSURL*)url pageLoaded:(BOOL)pageLoaded {
  if (!pageLoaded) {
    // query the webview for readystate
    NSString* readyState = [self.webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    pageLoaded = [readyState isEqualToString:@"loaded"] || [readyState isEqualToString:@"complete"];
  }

  if (pageLoaded) {
    // calls into javascript global function 'handleOpenURL'
    NSString* jsString = [NSString stringWithFormat:@"document.addEventListener('deviceready',function(){if (typeof handleOpenURL === 'function') { handleOpenURL(\"%@\");}});", url];
    [self.wkWebView evaluateJavaScript:jsString completionHandler:nil];
  } else {
    // save for when page has loaded
    self.url = url;
  }
}

- (void)copyLocalStorageToUIWebView:(NSNotification*)notification {
  if (self.uiWebViewLS != nil && self.wkWebViewLS != nil) {
    [[CDVLocalStorage class] copyFrom:self.wkWebViewLS to:self.uiWebViewLS error:nil];
  }
}

#pragma mark View lifecycle

- (void)createGapView:(WKWebViewConfiguration*) config
{
  CGRect webViewBounds = self.view.bounds;
  webViewBounds.origin = self.view.bounds.origin;

  self.wkWebView = [self newCordovaWKWebViewWithFrame:webViewBounds wkWebViewConfig:config];
  self.wkWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

  [self.wkWebView setOpaque:NO];
  NSString* setting = @"BackgroundColor";
  if ([self settingForKey:setting]) {
    self.wkWebView.backgroundColor = [self colorFromHexString:[self settingForKey:setting]];
    self.view.backgroundColor = self.wkWebView.backgroundColor;
  } else {
    self.wkWebView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor whiteColor];
  }

  _webViewOperationsDelegate = [[CDVWebViewOperationsDelegate alloc] initWithWebView:self.webView];

  [self.view addSubview:self.wkWebView];
  [self.view sendSubviewToBack:self.wkWebView];

  // plugins may do self.webView.superview which would evaluate to nil if we don't do this
  self.webView.hidden = true;
  [self.view addSubview:self.webView];
  [self.view sendSubviewToBack:self.webView];
}

- (void)recoverFromCrash
{
    // When an empty title is returned, WkWebView has crashed
    NSString* title = self.wkWebView.title;
    if ((title == nil) || [title isEqualToString:@""]) {
        if (_crashRecoveryActive) {
            NSLog(@"WkWebView crash detected, recovering... ");
            _crashRecoveryActive = false;
            [_crashRecoveryTimer invalidate];
            _crashRecoveryTimer = nil;
            AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [appDelegate createWindowAndStartWebServer:true];
        }
    } else {

        // Once the title has been reported back as valid, activate crash recovery
        _crashRecoveryActive = true;
    }
}

- (id)settingForKey:(NSString*)key
{
  return [[self settings] objectForKey:[key lowercaseString]];
}

- (void)setSetting:(id)setting forKey:(NSString*)key
{
  [[self settings] setObject:setting forKey:[key lowercaseString]];
}

// THIS FUNCTION WILL BE REMOVED WHEN WKWEBVIEW SUPPORTS FILE LOADING FROM OUTSIDE OF /tmp
- (NSURL *) copyToTMP:(NSURL *)url {
  NSString *fullPath = url.path;
  NSString *src = url.lastPathComponent;
  // Does file already exist at tmp?
  NSError *copyError = nil;
  if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src]]) {
    if (![[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src] error:&copyError]) {
      NSLog(@"Error deleting file: %@", [copyError localizedDescription]);
    }
  }

  // Copy to tmp
  if (![[NSFileManager defaultManager] copyItemAtPath:fullPath toPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src] error:&copyError]) {
    NSLog(@"Error copying file: %@", [copyError localizedDescription]);
    return url;
  }
  // Load from tmp
  return [[NSURL alloc] initFileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:src]];
}

- (BOOL)copyFrom:(NSString*)src to:(NSString*)dest error:(NSError* __autoreleasing*)error
{
  NSFileManager* fileManager = [NSFileManager defaultManager];

  if (![fileManager fileExistsAtPath:src]) {
    NSString* errorString = [NSString stringWithFormat:@"%@ file does not exist.", src];
    if (error != NULL) {
      (*error) = [NSError errorWithDomain:@"TestDomainTODO"
                                     code:1
                                 userInfo:[NSDictionary dictionaryWithObject:errorString
                                                                      forKey:NSLocalizedDescriptionKey]];
    }
    return NO;
  }

  BOOL destExists = [fileManager fileExistsAtPath:dest];

  // remove the dest
  if (destExists && ![fileManager removeItemAtPath:dest error:error]) {
    return NO;
  }

  // create path to dest
  if (!destExists && ![fileManager createDirectoryAtPath:[dest stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:error]) {
    return NO;
  }

  // copy src to dest
  return [fileManager copyItemAtPath:src toPath:dest error:error];
}

- (void)loadURL:(NSURL*)URL
{
    self.alreadyLoaded = true;
    // /////////////////
    [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
      _userAgentLockToken = lockToken;
      [CDVUserAgentUtil setUserAgent:self.userAgent lockToken:lockToken];
      NSURLRequest* appReq = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
      [self.wkWebView loadRequest:appReq];
    }];
}

- (void)setServerPort:(unsigned short)port
{
  if(self.alreadyLoaded) {
    // If we already loaded for some reason, we don't care about the local port.
    return;
  } else {
    _startURL = [NSURL URLWithString:[NSString stringWithFormat:
                                            @"http://localhost:%hu/%@",
                                            port,
                                            self.startPage]];
    [self loadURL:_startURL];
  }
}

- (void)viewDidLoad
{
  NSURL* appURL = nil;
  NSString* loadErr = nil;

  if ([self.startPage rangeOfString:@"://"].location != NSNotFound) {
    appURL = [NSURL URLWithString:self.startPage];
  } else if ([self.wwwFolderName rangeOfString:@"://"].location != NSNotFound) {
    appURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.wwwFolderName, self.startPage]];
  }

  // iOS9 (runtime) compatibility
  if (IsAtLeastiOSVersion(@"9.0")) {
    appURL = _startURL;
  }

  //// Fix the iOS 5.1 SECURITY_ERR bug (CB-347), this must be before the webView is instantiated ////
  NSString* backupWebStorageType = @"cloud"; // default value

  id backupWebStorage = [self settingForKey:@"BackupWebStorage"];
  if ([backupWebStorage isKindOfClass:[NSString class]]) {
    backupWebStorageType = backupWebStorage;
  }
  [self setSetting:backupWebStorageType forKey:@"BackupWebStorage"];

  if (IsAtLeastiOSVersion(@"5.1")) {
    [CDVLocalStorage __fixupDatabaseLocationsWithBackupType:backupWebStorageType];
  }

  NSNumber* allowInlineMediaPlayback = [self settingForKey:@"AllowInlineMediaPlayback"];
  BOOL mediaPlaybackRequiresUserAction = YES;  // default value
  if ([self settingForKey:@"MediaPlaybackRequiresUserAction"]) {
    mediaPlaybackRequiresUserAction = [(NSNumber*)[self settingForKey:@"MediaPlaybackRequiresUserAction"] boolValue];
  }

  // // Instantiate the WebView ///////////////

  if (!self.wkWebView) {
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    if ([self conformsToProtocol:@protocol(WKScriptMessageHandler)]) {
      [userContentController addScriptMessageHandler:self name:@"cordova"];
    }
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    if ([allowInlineMediaPlayback boolValue]) {
      config.allowsInlineMediaPlayback = YES;
    }
    config.mediaPlaybackRequiresUserAction = mediaPlaybackRequiresUserAction;
    config.userContentController = userContentController;
    BOOL suppressesIncrementalRendering = NO; // SuppressesIncrementalRendering - defaults to NO
    if ([self settingForKey:@"SuppressesIncrementalRendering"] != nil) {
      if ([self settingForKey:@"SuppressesIncrementalRendering"]) {
        suppressesIncrementalRendering = [(NSNumber*)[self settingForKey:@"SuppressesIncrementalRendering"] boolValue];
      }
    }
    config.suppressesIncrementalRendering = suppressesIncrementalRendering;
    [self createGapView:config];
  }

  // Configure WebView
  self.wkWebView.navigationDelegate = self;

  // register this viewcontroller with the NSURLProtocol, only after the User-Agent is set
  [CDVURLProtocol registerViewController:self];

  // /////////////////

  NSString* enableViewportScale = [self settingForKey:@"EnableViewportScale"];

  // NOTE: setting these because this is largely a copy-paste of the super class, it's not actually used of course because this is the 'old' webView
  self.webView.scalesPageToFit = [enableViewportScale boolValue];

  // Fire up CDVLocalStorage to work-around WebKit storage limitations: on all iOS 5.1+ versions for local-only backups, but only needed on iOS 5.1 for cloud backup.
  if (IsAtLeastiOSVersion(@"5.1") && (([backupWebStorageType isEqualToString:@"local"]) ||
                                      ([backupWebStorageType isEqualToString:@"cloud"] && !IsAtLeastiOSVersion(@"6.0")))) {
    [self registerPlugin:[[CDVLocalStorage alloc] initWithWebView:self.webView] withClassName:NSStringFromClass([CDVLocalStorage class])];
  };

  // Copy UIWebView to WKWebView so upgrading to the new webview is less of a pain in the ..
  NSString* appLibraryFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString* cacheFolder;

  if ([[NSFileManager defaultManager] fileExistsAtPath:[appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage/file__0.localstorage"]]) {
    cacheFolder = [appLibraryFolder stringByAppendingPathComponent:@"WebKit/LocalStorage"];
  } else {
    cacheFolder = [appLibraryFolder stringByAppendingPathComponent:@"Caches"];
  }
  self.uiWebViewLS = [cacheFolder stringByAppendingPathComponent:@"file__0.localstorage"];

  if (![self settingForKey:@"DisableLocalStorageSyncWithUIWebView"] || ![[self settingForKey:@"DisableLocalStorageSyncWithUIWebView"] boolValue]) {
    // copy the localStorage DB of the old webview to the new one (it's copied back when the app is suspended/shut down)
    self.wkWebViewLS = [[NSString alloc] initWithString: [appLibraryFolder stringByAppendingPathComponent:@"WebKit"]];

#if TARGET_IPHONE_SIMULATOR
    // the simulutor squeezes the bundle id into the path
    NSString* bundleIdentifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    self.wkWebViewLS = [self.wkWebViewLS stringByAppendingPathComponent:bundleIdentifier];
#endif

    self.wkWebViewLS = [self.wkWebViewLS stringByAppendingPathComponent:@"WebsiteData/LocalStorage/file__0.localstorage"];
    [[CDVLocalStorage class] copyFrom:self.uiWebViewLS to:self.wkWebViewLS error:nil];
  }

  /*
   * This is for iOS 4.x, where you can allow inline <video> and <audio>, and also autoplay them
   */
  if ([allowInlineMediaPlayback boolValue] && [self.webView respondsToSelector:@selector(allowsInlineMediaPlayback)]) {
    self.webView.allowsInlineMediaPlayback = YES;
  }
  if ((mediaPlaybackRequiresUserAction == NO) && [self.webView respondsToSelector:@selector(mediaPlaybackRequiresUserAction)]) {
    self.webView.mediaPlaybackRequiresUserAction = NO;
  }

  // By default, overscroll bouncing is allowed.
  // UIWebViewBounce has been renamed to DisallowOverscroll, but both are checked.
  BOOL bounceAllowed = YES;
  NSNumber* disallowOverscroll = [self settingForKey:@"DisallowOverscroll"];
  if (disallowOverscroll == nil) {
    NSNumber* bouncePreference = [self settingForKey:@"UIWebViewBounce"];
    bounceAllowed = (bouncePreference == nil || [bouncePreference boolValue]);
  } else {
    bounceAllowed = ![disallowOverscroll boolValue];
  }

  // prevent webView from bouncing
  // based on the DisallowOverscroll/UIWebViewBounce key in config.xml
  if (!bounceAllowed) {
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
      ((UIScrollView*)[self.webView scrollView]).bounces = NO;
      ((UIScrollView*)[self.wkWebView scrollView]).bounces = NO;
    } else {
      for (id subview in self.webView.subviews) {
        if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
          ((UIScrollView*)subview).bounces = NO;
        }
      }
      for (id subview in self.wkWebView.subviews) {
        if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
          ((UIScrollView*)subview).bounces = NO;
        }
      }
    }
  }

  NSString* decelerationSetting = [self settingForKey:@"UIWebViewDecelerationSpeed"];
  if (![@"fast" isEqualToString : decelerationSetting]) {
    [self.webView.scrollView setDecelerationRate:UIScrollViewDecelerationRateNormal];
    [self.wkWebView.scrollView setDecelerationRate:UIScrollViewDecelerationRateNormal];
  }

  // don't show scrollbars
  self.wkWebView.scrollView.showsHorizontalScrollIndicator = NO;
  self.wkWebView.scrollView.showsVerticalScrollIndicator = NO;

  /*
   * iOS 6.0 UIWebView properties
   */
  if (IsAtLeastiOSVersion(@"6.0")) {
    BOOL keyboardDisplayRequiresUserAction = YES; // KeyboardDisplayRequiresUserAction - defaults to YES
    if ([self settingForKey:@"KeyboardDisplayRequiresUserAction"] != nil) {
      if ([self settingForKey:@"KeyboardDisplayRequiresUserAction"]) {
        keyboardDisplayRequiresUserAction = [(NSNumber*)[self settingForKey:@"KeyboardDisplayRequiresUserAction"] boolValue];
      }
    }

    // property check for compiling under iOS < 6
    if ([self.webView respondsToSelector:@selector(setKeyboardDisplayRequiresUserAction:)]) {
      [self.webView setValue:[NSNumber numberWithBool:keyboardDisplayRequiresUserAction] forKey:@"keyboardDisplayRequiresUserAction"];
    }
  }

  /*
   * iOS 7.0 UIWebView properties
   */
  if (IsAtLeastiOSVersion(@"7.0")) {
    SEL ios7sel = nil;
    id prefObj = nil;

    CGFloat gapBetweenPages = 0.0; // default
    prefObj = [self settingForKey:@"GapBetweenPages"];
    if (prefObj != nil) {
      gapBetweenPages = [prefObj floatValue];
    }

    // property check for compiling under iOS < 7
    ios7sel = NSSelectorFromString(@"setGapBetweenPages:");
    if ([self.webView respondsToSelector:ios7sel]) {
      [self.webView setValue:[NSNumber numberWithFloat:gapBetweenPages] forKey:@"gapBetweenPages"];
    }

    CGFloat pageLength = 0.0; // default
    prefObj = [self settingForKey:@"PageLength"];
    if (prefObj != nil) {
      pageLength = [[self settingForKey:@"PageLength"] floatValue];
    }

    // property check for compiling under iOS < 7
    ios7sel = NSSelectorFromString(@"setPageLength:");
    if ([self.webView respondsToSelector:ios7sel]) {
      [self.webView setValue:[NSNumber numberWithBool:pageLength] forKey:@"pageLength"];
    }

    NSInteger paginationBreakingMode = 0; // default - UIWebPaginationBreakingModePage
    prefObj = [self settingForKey:@"PaginationBreakingMode"];
    if (prefObj != nil) {
      NSArray* validValues = @[@"page", @"column"];
      NSString* prefValue = [validValues objectAtIndex:0];

      if ([prefObj isKindOfClass:[NSString class]]) {
        prefValue = prefObj;
      }

      paginationBreakingMode = [validValues indexOfObject:[prefValue lowercaseString]];
      if (paginationBreakingMode == NSNotFound) {
        paginationBreakingMode = 0;
      }
    }

    // property check for compiling under iOS < 7
    ios7sel = NSSelectorFromString(@"setPaginationBreakingMode:");
    if ([self.webView respondsToSelector:ios7sel]) {
      [self.webView setValue:[NSNumber numberWithInteger:paginationBreakingMode] forKey:@"paginationBreakingMode"];
    }

    NSInteger paginationMode = 0; // default - UIWebPaginationModeUnpaginated
    prefObj = [self settingForKey:@"PaginationMode"];
    if (prefObj != nil) {
      NSArray* validValues = @[@"unpaginated", @"lefttoright", @"toptobottom", @"bottomtotop", @"righttoleft"];
      NSString* prefValue = [validValues objectAtIndex:0];

      if ([prefObj isKindOfClass:[NSString class]]) {
        prefValue = prefObj;
      }

      paginationMode = [validValues indexOfObject:[prefValue lowercaseString]];
      if (paginationMode == NSNotFound) {
        paginationMode = 0;
      }
    }

    // property check for compiling under iOS < 7
    ios7sel = NSSelectorFromString(@"setPaginationMode:");
    if ([self.webView respondsToSelector:ios7sel]) {
      [self.webView setValue:[NSNumber numberWithInteger:paginationMode] forKey:@"paginationMode"];
    }
  }

  // init startup plugins
  if ([self.startupPluginNames count] > 0) {
    [CDVTimer start:@"TotalPluginStartup"];

    for (NSString* pluginName in self.startupPluginNames) {
      [CDVTimer start:pluginName];
      [self getCommandInstance:pluginName];
      [CDVTimer stop:pluginName];
    }
    // Correct the frame, as plugins like statusbar may alter it.
    // No need to check for pluginname like 'statusbar' because others may alter it too.
    self.wkWebView.frame = self.webView.frame;

    [CDVTimer stop:@"TotalPluginStartup"];
  }

  if(appURL != nil) {
    [self loadURL:appURL];
  } else if(!_targetExistsLocally) {
    self.alreadyLoaded = true;
    loadErr = [NSString stringWithFormat:@"ERROR: Start Page at '%@' was not found.",
               self.startPage];
    NSLog(@"%@", loadErr);
    ///////////////////
    [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
      _userAgentLockToken = lockToken;

      [CDVUserAgentUtil setUserAgent:self.userAgent lockToken:lockToken];
      NSString* html = [NSString stringWithFormat:@"<html><body> %@ </body></html>",
                        loadErr];
      [self.wkWebView loadHTMLString:html baseURL:nil];
    }];
  } else {
    // we'll load once the HTTP server starts.
  }

  // Start timer which periodically checks whether the app is alive
  if (![self settingForKey:@"DisableCrashRecovery"] || ![[self settingForKey:@"DisableCrashRecovery"] boolValue]) {
    _crashRecoveryTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(recoverFromCrash) userInfo:nil repeats:YES];
  }
}

- (WKWebView*)newCordovaWKWebViewWithFrame:(CGRect)bounds wkWebViewConfig:(WKWebViewConfiguration*) config
{
  WKWebView* cordovaView = [[WKWebView alloc] initWithFrame:bounds configuration:config];
  NSLog(@"Using a WKWebView");
  _webViewUIDelegate = [[CDVWebViewUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
  cordovaView.UIDelegate = _webViewUIDelegate;

  ReroutingUIWebView *e = [[ReroutingUIWebView alloc] initWithFrame:bounds];
  e.wkWebView = cordovaView;
  self.webView = e;
  return cordovaView;
}


/*
#pragma mark WKNavigationDelegate implementation
// allow opening links like mailto: / tel:
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {

  if (!navigationAction.targetFrame.isMainFrame) {
    [webView loadRequest:navigationAction.request];
  }

  return nil;
}
 */


#pragma mark WKNavigationDelegate implementation
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
  // It's safe to release the lock even if this is just a sub-frame that's finished loading.
  [CDVUserAgentUtil releaseLock:&_userAgentLockToken];

  // Hide the Top Activity THROBBER in the Battery Bar
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

  [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPageDidLoadNotification object:self.webView]];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
  [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

  if (!navigationAction.targetFrame) {
    // links with target="_blank" need to open outside the app, but WKWebView doesn't allow it currently
    NSURL *url = navigationAction.request.URL;
    NSLog(@"Navigating to %@", url);
    UIApplication *app = [UIApplication sharedApplication];
    if ([app canOpenURL:url]) {
      [app openURL:url];
    }
  }
  decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark WKScriptMessageHandler implementation

#ifdef __IPHONE_8_0
- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
  if (![message.name isEqualToString:@"cordova"]) {
    return;
  }

  NSArray* jsonEntry = message.body; // NSString:callbackId, NSString:service, NSString:action, NSArray:args
  CDVInvokedUrlCommand* command = [CDVInvokedUrlCommand commandFromJson:jsonEntry];
  CDV_EXEC_LOG(@"Exec(%@): Calling %@.%@", command.callbackId, command.className, command.methodName);
  [self.commandQueue  execute:command];
}
#endif /* ifdef __IPHONE_8_0 */

#pragma mark Color Utility
// Assumes input like "0xFF00FF00" (0xAARRGGBB).
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:((rgbValue & 0xFF000000) >> 24)/255.0];
}

@end
