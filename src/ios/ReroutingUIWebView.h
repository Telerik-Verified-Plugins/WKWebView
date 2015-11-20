#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>
#import "MyMainViewController.h"

@interface ReroutingUIWebView : UIWebView {
}

@property (nonatomic, readonly, retain, strong) UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet WKWebView* wkWebView;
@property (nonatomic, strong) MyMainViewController* viewController;
@end
