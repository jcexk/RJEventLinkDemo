//
//  ViewController.m
//  RJEventLinkDemo
//
//  Created by 江其 on 2021/5/1.
//

#import "ViewController.h"
#import "RJFirstButton.h"
#import "RJSecondButtonProtocol.h"

@interface ViewController ()<RJSecondButtonProtocol>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    RJFirstButton *button = [RJFirstButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(100, 100, 200, 100);
    [button setTitle:@"first" forState:UIControlStateNormal];
    button.backgroundColor = UIColor.blackColor;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.view addSubview:button];
}

- (void)rj_secondButtonClick {
    NSLog(@"%s+++%s",__FILE__, __func__);
}

@end
