---
layout: post
title: "关于MVC中消息传递的一些思考(POP方向)"
date:  2021-04-30
tags: []
comments: true
author: jcexk
---
## 今天要分享内容：我在MVC/MVVM架构下，如何利用最少知道原则和POP来处理C层与V层之间的用户事件。
设计思路如下:
![-w656](https://github.com/jcexk/jcexk.github.io/blob/master/images/RJEventLinkDemo/16198072582547.jpg?raw=true)


-------

相信每个编程的同学都知道什么是MVC，这里还是简单介绍一下
* **Model层：** 数据处理层，包括网络请求，数据加工
* **View层：** 所有App上看得到的界面
* **Controller层：** Model 与 View层的中介，把Model数据在View上展示出来

![-w443](https://github.com/jcexk/jcexk.github.io/blob/master/images/RJEventLinkDemo/16197952923413.jpg?raw=true)

(图片来源：《Cocoa Design Pattern》， Erik M.Buck 和 Donald A.Yacktman著）
### MVC的好处不言多喻
* **低耦合：**业务逻辑层和视图层分离
* **高内聚：**只对外提供接口，具体实现只放在.m文件中，这种做法也比较符合`最少知道设计原则`
* **可复用：**完美的MVC实现，是可以把M和V层直接放在别的项目中引用，而不需要去解决文件依赖等问题。

在实际开发过程中，为了实现view复杂的UI效果，难免会需要将view层不断的去分层细化，可能Controller加载的firstiew中，还需要去addsubview自定义的视图secondView，甚至secondV还需要去加载thirdView。
![-w328](https://github.com/jcexk/jcexk.github.io/blob/master/images/RJEventLinkDemo/16198011118222.jpg?raw=true)

在MVC中，因为C层的作用是协调V层和M层，而V中嵌套最底层的thirdView中需要将用户的操作事件传递给Controller，去进行相应的操作，比如去请求列表数据之后去刷新UI，这个是很常见的操作。
在不借助其他第三方解决方案前提下，要想让Controller去执行操作，那么就需要把用户操作的消息事件传递给Controller，而如果嵌套过多的view，需要怎么办呢？
常规的解决办法是，一级级的把这个事件传递，thirdView->secondView->firstiew->Controller.
![-w693](https://github.com/jcexk/jcexk.github.io/blob/master/images/RJEventLinkDemo/16198070040060.jpg?raw=true)

而这种做法导致的结果是一个事件导致了一长串的事件链路，而且调试也需要一步步的去追踪，可能在中间的接受者只起到了消息传递的作用。那么有没有更好的解决办法呢?
有同学可能会说，直接发个通知啊，就没有这么多的中间层了。但这么做会一下几个缺点：
* 大量的通知不易管理
* 通知是一对多关系
* 通知会有延迟

今天我们自己动手来设计一个
### 解决方案
接下来向大家介绍一下，我在项目中遇到这种现象的解决方案，欢迎探讨。
我的办法是利用POP(面向协议编程)特性。
**1.**      为了解耦，单独创建一个协议文件，协议中用`require`关键字修饰需要实现的方法
**2.**      定义一个获取当前顶层Controller全局函数(项目中应该都会用到这个功能，但建议根据nextResponder获取当前视图所在的Controller)
**3.**      Controller继承该协议
**4.**      为了安全，在子视图中定义一个`weak`弱引用属性delegate
**5.**      重写delegate，在get方法中进行容错处理
**6.**      把事件转发给delegate去执行

这种实现方式，我觉得有以下几个有点：
* **低耦合：**对外并没有暴露过多的信息，类没有提供向外额外的接口，也不需要在Controller中导入相关view文件，而在C和V中也只是需要导入Protocol文件，并不在MVC中的那一层，符合`迪米特设计原则`核心思想：类间解耦。
* **遵循POP理念：**我只管声明接口，具体的实现我不参与你自己看着办，可能会有千人千面
* **简化流程：**节省了中间步骤，底层view直接把消息传递给Controller调度

这样就绕过了firstView(没有中间商赚差价)，而我们定义的delega只是一个载体，它是id<Protocol>类型，底层V和C之间并没有产生依赖关系，并没有增加MVC中V层与C层的耦合度，因为我们面向的是Protocol，而不是UIViewController。
以上就是我的实现思路，有不对的地方欢迎指正。
[源码地址](https://github.com/jcexk/RJEventLinkDemo)
### 关键代码
##### 1.创建顶层Controller全局函数和定义协议
```
@protocol RJSecondButtonProtocol
@required
- (void)rj_secondButtonClick;
@end

//在项目应该都会用到获取当前顶层controller功能
//接口是线程安全的
UIViewController *getCurrentVC(void) {
    ///下文中有分析
     __block UIViewController *currentVC = nil;
     __block BOOL isStop = NO;

    static UIViewController *(^getCurrentVCFrom)(UIViewController *) = ^ (UIViewController *rootVC) {
        if ([rootVC presentedViewController]) {
            // 视图是被presented出来的
            rootVC = [rootVC presentedViewController];
        }
        if ([rootVC isKindOfClass:[UITabBarController class]]) {
            // 根视图为UITabBarController
            return getCurrentVCFrom([(UITabBarController *)rootVC selectedViewController]);
        } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
            // 根视图为UINavigationController
            return getCurrentVCFrom([(UINavigationController *)rootVC visibleViewController]);
        } else {
            // 根视图为非导航类
            return rootVC;
        }
    };
    
     dispatch_block_t mainCB = ^{
         UIWindow *foundWindow = nil;
         NSArray  *windows = [[UIApplication sharedApplication]windows];
         for (UIWindow  *window in windows) {
             if (window.isKeyWindow) {
                 foundWindow = window;
                 break;
             }
         }
         isStop = YES;
         UIViewController *rootViewController = foundWindow.rootViewController;
         currentVC = getCurrentVCFrom(rootViewController);
     };
     //主线程安全
     if (NSThread.isMainThread) {
         mainCB();
     } else {
         dispatch_async(dispatch_get_main_queue(), ^{
             mainCB();
         });
     }
     while (isStop == NO) {}
     return currentVC;
}
```
##### 2.创建secondView、delegate重写和容错处理
```
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
```



