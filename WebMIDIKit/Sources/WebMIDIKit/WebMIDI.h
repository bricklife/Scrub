//
//  WebMIDI.h
//  
//
//  Created by Shinichiro Oba on 2022/09/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WebMIDI : NSObject

- (void)setupWebView:(WKWebView *)webView NS_SWIFT_NAME(setup(webView:));

@end
