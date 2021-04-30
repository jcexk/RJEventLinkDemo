//
//  RJSecondButton.m
//  RJEventLinkDemo
//
//  Created by 江其 on 2021/5/1.
//

#import "RJSecondButton.h"
#import "RJSecondButtonProtocol.h"

@interface RJSecondButton ()
@property(nonatomic, weak) id<RJSecondButtonProtocol> delegate;
@end

@implementation RJSecondButton
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self.delegate action:@selector(rj_secondButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (id<RJSecondButtonProtocol>)delegate {
    /**
     * 此处采用了获取当前顶层controller
     * 在实际运用中，也可以根据self.nextResponder获取当前视图所在的controller
     */
    UIViewController *vc = getCurrentVC();
    BOOL isok = [vc conformsToProtocol:@protocol(RJSecondButtonProtocol)];
#ifdef DEBUG
    //NSAssert已经在build setting中做了判断，RELEASE模式下不会执行，但为了安全还是手动加上DEBUG判断
    NSAssert(isok, @"没有实现RJSecondButtonProtocol协议");
#endif
    if (isok) {
        return (id<RJSecondButtonProtocol>)vc;
    }
    return nil;
}
@end
