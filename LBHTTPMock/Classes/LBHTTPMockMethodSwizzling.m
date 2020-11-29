//
//  LBHTTPMockMethodSwizzling.m
//  LBHTTPMock
//
//  Created by 刘兵 on 2020/11/30.
//

#import "LBHTTPMockMethodSwizzling.h"

IMP HTTPStubsReplaceMethod(SEL selector,
                             IMP newImpl,
                             Class affectedClass,
                             BOOL isClassMethod)
{
    Method origMethod = isClassMethod ? class_getClassMethod(affectedClass, selector) : class_getInstanceMethod(affectedClass, selector);
    IMP origImpl = method_getImplementation(origMethod);

    if (!class_addMethod(isClassMethod ? object_getClass(affectedClass) : affectedClass, selector, newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, newImpl);
    }

    return origImpl;
}
