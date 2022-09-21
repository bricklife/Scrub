//
//  WebMIDI.m
//  
//
//  Created by Shinichiro Oba on 2022/09/21.
//

#import "WebMIDI.h"
#import "../WebMIDIAPIShimForiOS/WebMIDIAPIPolyfill/WebViewDelegate.h"

@interface WebMIDI ()

@property (nonatomic, strong) WebViewDelegate *webViewDelegate;

@end

@implementation WebMIDI

- (void)setupWebView:(WKWebView *)webView
{
    WebViewDelegate *delegate = [WebViewDelegate new];
    delegate.midiDriver = [MIDIDriver new];
    delegate.confirmSysExAvailability = ^(NSString *url) {
        return YES;
    };
    
    NSString *polyfill_path = [SWIFTPM_MODULE_BUNDLE pathForResource:@"WebMIDIAPIPolyfill" ofType:@"js"];
    NSString *polyfill_script = [NSString stringWithContentsOfFile:polyfill_path encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:polyfill_script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [webView.configuration.userContentController addUserScript:script];
    [webView.configuration.userContentController addScriptMessageHandler:delegate name:@"onready"];
    [webView.configuration.userContentController addScriptMessageHandler:delegate name:@"send"];
    [webView.configuration.userContentController addScriptMessageHandler:delegate name:@"clear"];
    
    self.webViewDelegate = delegate;
}

@end
