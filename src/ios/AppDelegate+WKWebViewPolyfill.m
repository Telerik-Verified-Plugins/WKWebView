#import <objc/runtime.h>
#import "AppDelegate.h"
#import "MyMainViewController.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels for the embedded HTTP server: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@class HTTPServer;
HTTPServer *httpServer;

@implementation AppDelegate (WKWebViewPolyfill)

+ (void)load {
  // swap in our own viewcontroller which loads the wkwebview, but only in case we're running iOS 8+
  if (IsAtLeastiOSVersion(@"8.0")) {
    swizzleMethod([AppDelegate class],
                  @selector(application:didFinishLaunchingWithOptions:),
                  @selector(my_application:didFinishLaunchingWithOptions:));
  }
}

- (BOOL)my_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  
  self.window = [[UIWindow alloc] initWithFrame:screenBounds];
  self.window.autoresizesSubviews = YES;
  MyMainViewController *myMainViewController = [[MyMainViewController alloc] init];
  self.viewController = myMainViewController;
  self.window.rootViewController = myMainViewController;
  [self.window makeKeyAndVisible];
  
  // CocoaHTTPServer stuff below, for serving over http:// (instead of file://)
  
  // Configure our logging framework.
  // To keep things simple and fast, we're just going to log to the Xcode console.
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  // Create server using our custom MyHTTPServer class
  httpServer = [[HTTPServer alloc] init];

  // Serve files from our embedded Web folder
  NSString *webPath = myMainViewController.wwwFolderName;
  DDLogInfo(@"Setting document root: %@", webPath);
  
  [httpServer setDocumentRoot:webPath];
  
  [self startServer];
  
  [myMainViewController setServerPort:[httpServer listeningPort]];
  
  return YES;
}

- (BOOL)identity_application: (UIApplication *)application
                     openURL: (NSURL *)url
           sourceApplication: (NSString *)sourceApplication
                  annotation: (id)annotation {
  
  // call super
  return [self identity_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)startServer
{
  // Start the server
  NSError *error;
  
  // The first port we'll try to bind to is 12344 (for backwards compatibiltiy)
  int httpPort = 12344;
  [httpServer setPort:httpPort];
  
  while(![httpServer start:&error]) {
    [httpServer setPort:(httpPort++)];
  }
  
  DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [self startServer];
  DDLogInfo(@"Restarted HTTP Server on port %hu", [httpServer listeningPort]);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // There is no public(allowed in AppStore) method for iOS to run continiously in the background for our purposes (serving HTTP).
  // So, we stop the server when the app is paused (if a users exits from the app or locks a device) and
  // restart the server when the app is resumed (based on this document: http://developer.apple.com/library/ios/#technotes/tn2277/_index.html )
  
  DDLogInfo(@"Stopped HTTP Server on port %hu", [httpServer listeningPort]);
  [httpServer stop];
}

@end


#pragma mark Swizzling

static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector) {
  Method destinationMethod = class_getInstanceMethod(class, destinationSelector);
  Method sourceMethod = class_getInstanceMethod(class, sourceSelector);
  
  // If the method doesn't exist, add it.  If it does exist, replace it with the given implementation.
  if (class_addMethod(class, destinationSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod))) {
    class_replaceMethod(class, destinationSelector, method_getImplementation(destinationMethod), method_getTypeEncoding(destinationMethod));
  } else {
    method_exchangeImplementations(destinationMethod, sourceMethod);
  }
}
