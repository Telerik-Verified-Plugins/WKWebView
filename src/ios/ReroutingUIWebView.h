#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>

@interface ReroutingUIWebView : UIWebView {
}

@property (nonatomic, readonly, retain, strong) UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet WKWebView* wkWebView;

@end