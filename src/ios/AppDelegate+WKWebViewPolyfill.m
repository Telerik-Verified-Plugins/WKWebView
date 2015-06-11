#import <objc/runtime.h>
#import "AppDelegate.h"
#import "MyMainViewController.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerPrivate.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@implementation AppDelegate (WKWebViewPolyfill)

NSString *const FileSchemaConstant = @"file://";
NSString *const ServerCreatedNotificationName = @"WKWebView.WebServer.Created";
GCDWebServer* _webServer;
NSMutableDictionary* _webServerOptions;
NSString* appDataFolder;

+ (void)load {
    // Swap in our own viewcontroller which loads the wkwebview, but only in case we're running iOS 8+
    if (IsAtLeastiOSVersion(@"8.0")) {
        swizzleMethod([AppDelegate class],
                      @selector(application:didFinishLaunchingWithOptions:),
                      @selector(my_application:didFinishLaunchingWithOptions:));
    }
}

- (BOOL)my_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [self createWindowAndStartWebServer:true];
    return YES;
}

- (void) createWindowAndStartWebServer:(BOOL) startWebServer {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    self.window.autoresizesSubviews = YES;
    MyMainViewController *myMainViewController = [[MyMainViewController alloc] init];
    self.viewController = myMainViewController;
    self.window.rootViewController = myMainViewController;
    [self.window makeKeyAndVisible];
    appDataFolder = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByDeletingLastPathComponent];

    // Initialize Server environment variables
    NSString *directoryPath = myMainViewController.wwwFolderName;
    _webServer = [[GCDWebServer alloc] init];
    _webServerOptions = [NSMutableDictionary dictionary];
    
    // Add GET handler for local "www/" directory
    [_webServer addGETHandlerForBasePath:@"/"
                           directoryPath:directoryPath
                           indexFilename:nil
                                cacheAge:60
                      allowRangeRequests:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ServerCreatedNotificationName object: @[myMainViewController, _webServer]];
    
    [self addHandlerForPath:@"/Library/"];
    [self addHandlerForPath:@"/Documents/"];

    // Initialize Server startup
    if (startWebServer) {
        [self startServer];
    }
    
    // Update Swizzled ViewController with port currently used by local Server
    [myMainViewController setServerPort:_webServer.port];
}

- (void)addHandlerForPath:(NSString *) path {
  [_webServer addHandlerForMethod:@"GET"
                        pathRegex:[@".*" stringByAppendingString:path]
                     requestClass:[GCDWebServerRequest class]
                     processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                       NSString *fileLocation = request.URL.path;
                       if ([fileLocation hasPrefix:path]) {
                         fileLocation = [appDataFolder stringByAppendingString:request.URL.path];
                       }
                       
                       fileLocation = [fileLocation stringByReplacingOccurrencesOfString:FileSchemaConstant withString:@""];
                       if (![[NSFileManager defaultManager] fileExistsAtPath:fileLocation]) {
                           return nil;
                       }
                         
                       return [GCDWebServerFileResponse responseWithFile:fileLocation];
                     }
   ];
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
    NSError *error = nil;

    // Enable this option to force the Server also to run when suspended
    //[_webServerOptions setObject:[NSNumber numberWithBool:NO] forKey:GCDWebServerOption_AutomaticallySuspendInBackground];

    [_webServerOptions setObject:[NSNumber numberWithBool:YES]
                          forKey:GCDWebServerOption_BindToLocalhost];

    // Initialize Server listening port, initially trying 12344 for backwards compatibility
    int httpPort = 12344;

    // Start Server
    do {
        [_webServerOptions setObject:[NSNumber numberWithInteger:httpPort++]
                              forKey:GCDWebServerOption_Port];
    } while(![_webServer startWithOptions:_webServerOptions error:&error]);

    if (error) {
        NSLog(@"Error starting http daemon: %@", error);
    } else {
        [GCDWebServer setLogLevel:kGCDWebServerLoggingLevel_Warning];
        NSLog(@"Started http daemon: %@ ", _webServer.serverURL);
    }
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
