//
//  ViewController.m
//  iOS音视频播放总结1
//
//  Created by zyl on 16/6/29.
//  Copyright © 2016年 央广视讯. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import "ZYLButton.h"

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,
    DirectionUpOrDown,
    DirectionNone
};

@interface ViewController () <AVPlayerViewControllerDelegate, ZYLButtonDelegate>

@property (strong, nonatomic) AVPlayer *avPlayer;

@property (assign, nonatomic) NSTimeInterval total;

@property (strong, nonatomic) CADisplayLink *link;

@property (assign, nonatomic) NSTimeInterval lastTime;

@property (strong, nonatomic) ZYLButton *button;

@property (assign, nonatomic) Direction direction;

@property (assign, nonatomic) CGPoint startPoint;

@property (assign, nonatomic) CGFloat startVB;

@property (assign, nonatomic) CGFloat startVideoRate;

@property (strong, nonatomic) MPVolumeView *volumeView;//控制音量的view

@property (strong, nonatomic) UISlider* volumeViewSlider;//控制音量

@property (assign, nonatomic) CGFloat currentRate;//当期视频播放的进度

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *playUrl = @"";
    //请自行找链接测试
    AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:playUrl]];
    //初始化AVPlayer
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:playItem];
    //设置AVPlayer关联
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    //设置视频模式
    playerLayer.videoGravity = AVLayerVideoGravityResize;
    playerLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 9.0 / 16.0);
    //创建一个UIView与AVPlayerLayer关联
    UIView *playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, CGRectGetWidth(playerLayer.frame), CGRectGetHeight(playerLayer.frame))];
    playerView.backgroundColor = [UIColor blackColor];
    [playerView.layer addSublayer:playerLayer];
    
    [self.view addSubview:playerView];
    
    //添加监听
    [playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(upadte)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    //添加自定义的Button到视频画面上
    self.button = [[ZYLButton alloc] initWithFrame:playerLayer.frame];
    self.button.touchDelegate = self;
    [playerView addSubview:self.button];
    self.volumeView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 9.0 / 16.0);
}

#pragma mark - 自定义Button的代理***********************************************************
#pragma mark - 开始触摸
/*************************************************************************/
- (void)touchesBeganWithPoint:(CGPoint)point {
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.button.frame.size.width / 2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音/量
        self.startVB = self.volumeViewSlider.value;
    }
    //方向置为无
    self.direction = DirectionNone;
    //记录当前视频播放的进度
    CMTime ctime = self.avPlayer.currentTime;
    self.startVideoRate = ctime.value / ctime.timescale / self.total;
    
}

#pragma mark - 结束触摸
- (void)touchesEndWithPoint:(CGPoint)point {
    if (self.direction == DirectionLeftOrRight) {
        [self.avPlayer seekToTime:CMTimeMakeWithSeconds(self.total * self.currentRate, 1) completionHandler:^(BOOL finished) {
            //在这里处理进度设置成功后的事情
        }];
    }
}

#pragma mark - 拖动 
- (void)touchesMoveWithPoint:(CGPoint)point {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    //分析出用户滑动的方向
    if (self.direction == DirectionNone) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = DirectionLeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = DirectionUpOrDown;
        }
    }
    
    if (self.direction == DirectionNone) {
        return;
    } else if (self.direction == DirectionUpOrDown) {
        //音量和亮度
        if (self.startPoint.x <= self.button.frame.size.width / 2.0) {
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
            }
            
        } else {
            //音量
            if (panPoint.y < 0) {
                //增大音量
                [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }
                
            } else {
                //减少音量
                [self.volumeViewSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
        }
    } else if (self.direction == DirectionLeftOrRight ) {
        //进度
        CGFloat rate = self.startVideoRate + (panPoint.x / 30.0 / 20.0);
        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        self.currentRate = rate;
    }
}

- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

- (void)upadte
{
    NSTimeInterval current = CMTimeGetSeconds(self.avPlayer.currentTime);
    
    if (current!=self.lastTime) {
        //没有卡顿
        NSLog(@"没有卡顿");
    }else{
        //卡顿了
        NSLog(@"卡顿了");
    }
    self.lastTime = current;
}

//监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        //获取缓冲进度
        NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
        // 获取缓冲区域
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
        //开始的时间
        NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
        //表示已经缓冲的时间
        NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
        // 计算缓冲总时间
        NSTimeInterval result = startSeconds + durationSeconds;
        NSLog(@"开始:%f,持续:%f,总时间:%f", startSeconds, durationSeconds, result);
        NSLog(@"视频的加载进度是:%%%f", durationSeconds / self.total * 100);
    }else if ([keyPath isEqualToString:@"status"]){
        //获取播放状态
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"准备播放");
            //获取视频的总播放时长
            [self.avPlayer play];
            self.total = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
            CMTime ctime = self.avPlayer.currentTime;
            CGFloat currentTimeSec = ctime.value / ctime.timescale;
            NSLog(@"当前播放时间:%f", currentTimeSec);
        } else{
            NSLog(@"播放失败");
        }
    }
    
}







@end
