//
//  RJFirseButton.m
//  RJEventLinkDemo
//
//  Created by 江其 on 2021/5/1.
//

#import "RJFirstButton.h"
#import "RJSecondButton.h"

@implementation RJFirstButton
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        RJSecondButton *button1 = [RJSecondButton buttonWithType:UIButtonTypeRoundedRect];
        button1.frame=CGRectMake(60, 20, 80, 60);
        button1.backgroundColor = UIColor.orangeColor;
        [button1 setTitle:@"second" forState:UIControlStateNormal];
        button1.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self addSubview:button1];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
