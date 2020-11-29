//
//  LBHTTPMockMethodSwizzling.h
//  LBHTTPMock
//
//  Created by 刘兵 on 2020/11/30.
//

#import <objc/runtime.h>

__attribute__((warn_unused_result)) IMP HTTPStubsReplaceMethod(SEL selector,
                                                               IMP newImpl,
                                                               Class affectedClass,
                                                               BOOL isClassMethod);
