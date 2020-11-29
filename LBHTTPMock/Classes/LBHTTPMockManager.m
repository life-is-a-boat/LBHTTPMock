//
//  LBHTTPMockManager.m
//  LBHTTPMock
//
//  Created by 刘兵 on 2020/11/30.
//

#import "LBHTTPMockManager.h"
#import "LBHTTPURLProtocol.h"
@interface LBHTTPMockManager ()

@property (nonatomic, assign,) BOOL enable;//是否监听 开关

@end
@implementation LBHTTPMockManager
static LBHTTPMockManager *shareInstance = nil;
//单例
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shareInstance == nil) {
            shareInstance = [[LBHTTPMockManager alloc] init];
        }
    });
    return shareInstance;
}

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (void)setEnable:(BOOL)enable {
    [[LBHTTPMockManager share] setEnable:enable];
}

- (void)setEnable:(BOOL)enable {
    @synchronized (self) {
        _enable = enable;
        if (enable) {
            [NSURLProtocol registerClass:LBHTTPURLProtocol.class];
        }
        else {
            [NSURLProtocol unregisterClass:LBHTTPURLProtocol.class];
        }
    }
}

- (BOOL)isEnable {
    BOOL enable = false;
    @synchronized (self) {
        enable = _enable;
    }
    return enable;
}

//比较重要的几个方法
#if defined(__IPHONE_7_0) || defined(__MAC_10_9)
+ (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        Class protoCls = LBHTTPURLProtocol.class;
        if (enable && ![urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        else if (!enable && [urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses removeObject:protoCls];
        }
        sessionConfig.protocolClasses = urlProtocolClasses;
    }
    else
    {
        NSLog(@"[OHHTTPStubs] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
    }
}

+ (BOOL)isEnabledForSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        Class protoCls = LBHTTPURLProtocol.class;
        return [urlProtocolClasses containsObject:protoCls];
    }
    else
    {
        NSLog(@"[OHHTTPStubs] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
        return NO;
    }
}
#endif


@end
