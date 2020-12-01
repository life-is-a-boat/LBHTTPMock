//
//  LBHTTPMockManager.h
//  LBHTTPMock
//
//  Created by 刘兵 on 2020/11/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBHTTPMockManager : NSObject

@property (nonatomic, assign, readonly) BOOL isEnable; //是否需要拦截
@property (nonatomic, copy, readwrite) NSString *hookURL; //需要拦截的的URL
@property (nonatomic, copy, readwrite) NSString *redirectURL; //重定向的URL
@property (nonatomic, strong, readwrite) NSArray *ignoreURLs; //不需要重定向的URLs


//开关
+ (void)setEnable:(BOOL)enable;

//单例
+ (instancetype)share;


#if defined(__IPHONE_7_0) || defined(__MAC_10_9)
+ (BOOL)isEnabledForSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig;
+ (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig;
#endif

@end

NS_ASSUME_NONNULL_END
