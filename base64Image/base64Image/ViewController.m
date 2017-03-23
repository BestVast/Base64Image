//
//  ViewController.m
//  base64Image
//
//  Created by njxh on 17/3/3.
//  Copyright © 2017年 LianghaoAn. All rights reserved.
//
#define Screen_Width ([[UIScreen mainScreen] bounds].size.width)
#define Screen_Height ([[UIScreen mainScreen] bounds].size.height)
#import "ViewController.h"
#import "OpenCameraManager.h"
#import <WebKit/WebKit.h>
@interface ViewController () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *myWKWebView;
@property (nonatomic, strong) WKUserContentController *userContentController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createCustomView];
}
- (void)createCustomView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    _userContentController = [[WKUserContentController alloc] init];
    configuration.userContentController = _userContentController;
    _myWKWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, Screen_Width, Screen_Height) configuration:configuration];
    _myWKWebView.backgroundColor = [UIColor redColor];
    _myWKWebView.scrollView.bounces = NO;
    _myWKWebView.UIDelegate = self;
    _myWKWebView.navigationDelegate = self;
    [self.view addSubview:_myWKWebView];
    
    NSString *urlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    [_myWKWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:urlPath]]];

    //注册方法
    //登录
    [_userContentController addScriptMessageHandler:self name:@"selectImage"];

}
#pragma mark  ==WKScriptMessageHandler==
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"name:%@\\\\n body:%@\\\\n",message.name,message.body);
    if ([message.name isEqualToString:@"selectImage"]) {
//        [self hhlLogin:message.body];
        [self openCamera:message.body[@"callback"]];
    }
}
//加载网页地址
- (void)reloadWKWebViewHtmlPath:(NSString *)path
{
    [_myWKWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: path]]];
    //    [_myWKWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}
- (void)openCamera:(NSString *)callback
{
    [[OpenCameraManager defaultCameraAudioManager] takeCameraAndAudioWithImageName:@"test" WithViewController:self WithType:@"camear"];
    [OpenCameraManager defaultCameraAudioManager].cameraAudioBlock = ^(NSString *description, UIImage *image) {
        if (image) {
            NSString *string = [self image2DataURL:image];
//            JSValue *picValue = self.jsContext[_loginMethodString];
//            [picValue callWithArguments:@[string]];
            [self callbackJSMethodParameter:string callbackMethod:callback];
        }
    };
}
- (NSString *)image2DataURL:(UIImage *)image
{
    NSData *imageData = nil;
    NSString *mimeType = nil;
    
    if ([self imageHasAlpha: image]) {
        imageData = UIImagePNGRepresentation(image);
        mimeType = @"image/png";
    } else {
        imageData = UIImageJPEGRepresentation(image, 1.0f);
        mimeType = @"image/jpeg";
    }
    NSLog(@"data-%@", imageData);
    return [NSString stringWithFormat:@"data:%@;base64,%@", mimeType,
            [imageData base64EncodedStringWithOptions: 0]];
}
- (BOOL) imageHasAlpha: (UIImage *) image
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}



#pragma mark ==调用第三方之后回调js的方法==
- (void)callbackJSMethodParameter:(id)jsParameter callbackMethod:(NSString *)methodString
{
    //返回给web的是对象，让web自己处理
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSString *js = [NSString stringWithFormat:@"%@(%@)", methodString, jsParameter];
            //回调js方法
            [_myWKWebView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"callbackWKWebViewJS->%@\nerror->%@\n methodString->%@\n mutableString->%@", result, error.localizedDescription, methodString, jsParameter);
                }
            }];
        });
    });
}



#pragma mark - WKNavigationDelegate
// 1、在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
}
// 2、页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{}
// 3、在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
}
// 4、当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{}
// 5、页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
{}
// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{}


#pragma mark - WKUIDelegate
// 创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    return [[WKWebView alloc]init];
}
// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"输入框" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText;
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(@"");
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (alertVc.textFields[0].text.length > 0) {
            completionHandler(alertVc.textFields[0].text);
        }
        else {
            completionHandler(@"");
        }
    }];
    [alertVc addAction:action1];
    [alertVc addAction:action2];
    [self presentViewController:alertVc animated:YES completion:nil];
}
// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"确认框" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }];
    [alertVc addAction:action1];
    [alertVc addAction:action2];
    [self presentViewController:alertVc animated:YES completion:nil];
}
// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"警告框" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alertVc addAction:action1];
    [self presentViewController:alertVc animated:YES completion:nil];
}

@end
