//
//  LBHTTPURLProtocol.m
//  LBHTTPMock
//
//  Created by 刘兵 on 2020/11/30.
//

#import "LBHTTPURLProtocol.h"
#import "LBHTTPMockManager.h"
#import "LBHTTPMockMethodSwizzling.h"
#import <objc/runtime.h>

#define URLProtocolHandledKey   @"URLProtocolHandledKey"


@interface LBHTTPMockManager (protocol)
@property (nonatomic, strong) NSURLSession *redirectSession;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@end

@implementation LBHTTPMockManager (protocol)

- (void)setRedirectSession:(NSURLSession *)redirectSession {
    objc_setAssociatedObject(self, "ATURLProtocol_session", redirectSession, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSURLSession *)redirectSession {
    return objc_getAssociatedObject(self, "ATURLProtocol_session");
}

- (void)setDataTask:(NSURLSessionDataTask *)dataTask {
    objc_setAssociatedObject(self, "ATURLProtocol_dataTask", dataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSURLSessionDataTask *)dataTask {
    return objc_getAssociatedObject(self, "ATURLProtocol_dataTask");
}

@end

@interface LBHTTPURLProtocol () <NSURLSessionTaskDelegate>
@property(assign) CFRunLoopRef clientRunLoop;
@end
@implementation LBHTTPURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    printf("_________URL:%s\n",request.URL.absoluteString.UTF8String);
    //已经拦截过的就不再k拦截，避免死循环
    if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
       return false;
    }
    //不需要hook的URL
    for (NSString *url in [LBHTTPMockManager share].ignoreURLs) {
        if ([request.URL.absoluteString containsString:url]) {
            return false;
        }
    }
    //需要hook的URL
    if ([request.URL.absoluteString containsString:[LBHTTPMockManager share].hookURL]) {
        return true;
    }
    
    if ([request.URL.absoluteString containsString:[LBHTTPMockManager share].redirectURL]) {
        return false;
    }
    
    return false;
}
- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(nullable NSCachedURLResponse *)cachedResponse client:(nullable id <NSURLProtocolClient>)client {
    printf("_________%s\n",__func__);
    LBHTTPURLProtocol *protocol = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    return protocol;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    printf("_________%s\n",__func__);
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    mutableReqeust = [self redirectHostInRequset:mutableReqeust];
    return mutableReqeust;
}

+(NSMutableURLRequest*)redirectHostInRequset:(NSMutableURLRequest*)request
{
    if ([request.URL host].length == 0) {
        return request;
    }

    NSString *originUrlString = [request.URL absoluteString];
    NSString *originHostString = [request.URL host];
    NSRange hostRange = [originUrlString rangeOfString:originHostString];
    if (hostRange.location == NSNotFound) {
        return request;
    }
    //定向到bing搜索主页
    NSString *ip = [LBHTTPMockManager share].redirectURL;

    // 替换域名
    NSString *urlString = [ip stringByAppendingString:request.URL.path];
    NSURL *url = [NSURL URLWithString:urlString];
    request.URL = url;

    return request;
}

- (void)startLoading {
    printf("_________%s\n",__PRETTY_FUNCTION__);
    //重定向
    NSMutableURLRequest* mutableReqeust = [[self request] mutableCopy];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    // 封装custom headers
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[self class]];//注意这里的实现需要的是当前类的class类型 并非类本身
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
//    [LBHTTPMockManager share].redirectBlock(request);
    [LBHTTPMockManager share].redirectSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    [LBHTTPMockManager share].dataTask = [[LBHTTPMockManager share].redirectSession dataTaskWithRequest:mutableReqeust];
    [[LBHTTPMockManager share].dataTask resume];
    
    
//    self.clientRunLoop = CFRunLoopGetCurrent();
//    //当前的request
//    NSURLRequest *request = self.request;
////    id<NSURLProtocolClient> client = self.client;
//
//    ATHTTPStubResponse *responseStub = self.stub.responseBlock(request);
////
//    if (responseStub.error == nil) {
////        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:responseStub.statusCode HTTPVersion:@"HTTP/1.1" headerFields:responseStub.httpHeaders];
//        [self executeOnClientRunLoopAfterDelay:responseStub.requestTime block:^{
//            [self.client URLProtocolDidFinishLoading:self];
//        }];
//    }
    
}

/** Drop certain headers in accordance with
 * https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders
 */
- (NSMutableURLRequest *)clearAuthHeadersForRequest:(NSMutableURLRequest *)request {
    NSArray* authHeadersToRemove = @[
                                     @"Authorization",
                                     @"Connection",
                                     @"Host",
                                     @"Proxy-Authenticate",
                                     @"Proxy-Authorization",
                                     @"WWW-Authenticate"
                                     ];
    for (NSString* header in authHeadersToRemove) {
        [request setValue:nil forHTTPHeaderField:header];
    }
    return request;
}

+ (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument {
    printf("_________%s\n",__func__);
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    printf("_________%s\n",__func__);
    return true;
}

- (void)stopLoading {
    printf("_________%s\n",__func__);
    [[LBHTTPMockManager share].dataTask cancel];
    [LBHTTPMockManager share].dataTask = nil;
}

//延时执行操作
- (void)executeOnClientRunLoopAfterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)block {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFRunLoopPerformBlock(self.clientRunLoop, kCFRunLoopDefaultMode, block);
        CFRunLoopWakeUp(self.clientRunLoop);
    });
}

#pragma mark - url session delegate
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    completionHandler(request);//取消重定向的请求
//        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}
@end

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static NSURLSessionConfiguration* HTTPStubs_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    [LBHTTPMockManager setEnabled:YES forSessionConfiguration:config]; //OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

static NSURLSessionConfiguration* HTTPStubs_ephemeralSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    [LBHTTPMockManager setEnabled:YES forSessionConfiguration:config]; //OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

@implementation NSURLSessionConfiguration (HTTPStubs)

+(void)load
{
    orig_defaultSessionConfiguration = (SessionConfigConstructor)HTTPStubsReplaceMethod(@selector(defaultSessionConfiguration),
                                                                                          (IMP)HTTPStubs_defaultSessionConfiguration,
                                                                                          [NSURLSessionConfiguration class],
                                                                                          YES);
    orig_ephemeralSessionConfiguration = (SessionConfigConstructor)HTTPStubsReplaceMethod(@selector(ephemeralSessionConfiguration),
                                                                                            (IMP)HTTPStubs_ephemeralSessionConfiguration,
                                                                                            [NSURLSessionConfiguration class],
                                                                                            YES);
}

@end
