#import <objc/runtime.h>
#import "AppDelegate.h"
#import "AppDelegate+WKWebViewPolyfill.h"
#import "MyMainViewController.h"

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@implementation WKWebViewPolyfill
- (void) loadFile:(CDVInvokedUrlCommand*)command {
  NSString *file = [command.arguments objectAtIndex:0];
  CDVPluginResult * pluginResult;
}

@end

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
  self.viewController = [[MyMainViewController alloc] init];
  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  
  return YES;
}

- (BOOL)identity_application: (UIApplication *)application
                     openURL: (NSURL *)url
           sourceApplication: (NSString *)sourceApplication
                  annotation: (id)annotation {

    // call super
  return [self identity_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
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
