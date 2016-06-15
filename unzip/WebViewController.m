//
//  WebViewController.m
//  unzip
//
//  Created by xiangwenwen on 15/11/15.
//  Copyright © 2015年 xiangwenwen. All rights reserved.
//

#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#import "WebViewController.h"
#import "unzip-Swift.h"

@interface WebViewController()<UIWebViewDelegate,ValiantFetchZipManagerDelegate>
@property(nonatomic, strong) WebViewJavascriptBridge *bridge;
@property(nonatomic, strong) UIWebView *webview;
@property(nonatomic, copy) NSString *doc;
@property(nonatomic, strong) ValiantFetchZipManager *valiant;
@property(nonatomic, strong) ValiantCenterManager *valiantCenter;
@end

@implementation WebViewController

-(UIWebView *)webview
{
    if (!_webview) {
        _webview = [[UIWebView alloc] initWithFrame:self.view.frame];
    }
    return _webview;
}

-(ValiantFetchZipManager *)valiant
{
    if (!_valiant) {
        _valiant = [[ValiantFetchZipManager alloc] init];
    }
    return _valiant;
}

-(ValiantCenterManager *)valiantCenter
{
    if (!_valiantCenter) {
        _valiantCenter = [ValiantCenterManager sharedInstanceManager];
    }
    return _valiantCenter;
}

-(WebViewJavascriptBridge *)bridge
{
    if (!_bridge) {
        _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webview webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
            responseCallback(@"启动 webview bridge");
        }];
    }
    return _bridge;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.webview];
    //webviewbridge
    [self.bridge registerHandler:@"authR...." handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback(@"hello");
    }];
    
    [self.valiantCenter fetchContainerRun:@"app"];
    NSString *baseUrlString = [self.valiantCenter fetchContainerPath:@"app" sourcePath:@"index.html"];
    NSArray *baseUrlArray = [self.valiantCenter fetchContainerPath:@"app" recursivePath:@"discovery"];
    
    NSLog(@"base url string --- > %@",baseUrlString);
    NSLog(@"base url array --- > %@",baseUrlArray);
    
    /**
     *  delegate版
     */
    
    //    [self.valiant startFetchZip];
    //     self.valiant.delegate = self;
    
    
    /**
     *  block版
     */
    
    __weak typeof(self) weakSelf = self;
    [self.valiant startFetchZip:^(NSError *error, NSDictionary *location) {
        NSLog(@"zip包解压成功 block  --- > %@",location);
        if (!error) {
            NSURL *baseUrl = [weakSelf.valiantCenter fetchContainerRun:@"app" runPageURL:@"index.html?communityId=1&discovery"];
            NSString *basePath = [weakSelf.valiantCenter fetchContainerPath:@"app" sourcePath:@"index.html"];
            NSLog(@"basePath ---> %@",basePath);
            NSString *htmlString = [NSString stringWithContentsOfFile:basePath encoding:NSUTF8StringEncoding error:nil];
            [weakSelf.webview loadHTMLString:htmlString baseURL:baseUrl];
        }else{
            NSLog(@"%@",error);
        }
    } completion:^{
        NSLog(@"最后运行");
    }];
}

-(void)managerUnZipDidFinishLoading:(NSDictionary *)location
{
    NSURL *baseUrl = [self.valiantCenter fetchContainerRun:@"app" runPageURL:@"index.html?communityId=1&discovery"];
    NSString *basePath = [self.valiantCenter fetchContainerPath:@"app" sourcePath:@"index.html"];
    NSLog(@"basePath ---> %@",basePath);
    NSString *htmlString = [NSString stringWithContentsOfFile:basePath encoding:NSUTF8StringEncoding error:nil];
    [self.webview loadHTMLString:htmlString baseURL:baseUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    NSLog(@"WebViewController release memory");
}

@end
