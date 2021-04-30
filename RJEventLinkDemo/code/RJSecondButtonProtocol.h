//
//  Header.h
//  RJEventLinkDemo
//
//  Created by 江其 on 2021/5/1.
//

#ifndef Header_h
#define Header_h

//在项目应该都会用到获取当前顶层controller功能
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

@protocol RJSecondButtonProtocol

@required
- (void)rj_secondButtonClick;

@end
#endif /* Header_h */
