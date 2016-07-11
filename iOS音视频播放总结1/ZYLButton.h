//
//  ZYLButton.h
//  CNRMobilePhoneTV
//
//  Created by zyl on 16/5/17.
//  Copyright © 2016年 央广视讯. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZYLButtonDelegate <NSObject>

/**
 * 开始触摸
 */
- (void)touchesBeganWithPoint:(CGPoint)point;

/**
 * 结束触摸
 */
- (void)touchesEndWithPoint:(CGPoint)point;

/**
 * 移动手指
 */
- (void)touchesMoveWithPoint:(CGPoint)point;

@end

@interface ZYLButton : UIButton

/**
 * 传递点击事件的代理
 */
@property (weak, nonatomic) id <ZYLButtonDelegate> touchDelegate;

@end
