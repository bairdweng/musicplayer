//
//  VoiceHelper.m
//  pro
//
//  Created by Xiaowz on 16/10/10.
//  Copyright © 2016年 huaxia. All rights reserved.
//

#import "VoiceHelper.h"
#import <AVFoundation/AVFoundation.h>


//const static int max_height = 250;

@interface VoiceHelper() {
    NSTimer *_timer;
}
@property (nonatomic, strong) AVAudioRecorder *recorder;
@end

@implementation VoiceHelper

static VoiceHelper *_instance;
+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [VoiceHelper new];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self configSelf];
    }
    return self;
}

#pragma mark - call back
- (void)levelTimerCallback:(NSTimer *)timer {
    [_recorder updateMeters];
    //float tmep = [_recorder averagePowerForChannel:0];
    float temp = [_recorder peakPowerForChannel:0];
    //NSLog(@"%f,%f",tmep,temp);
    //转化范围为0 － 1；
    double result = pow(10, (0.05 * temp));
    //float height = result * (arc4random() % max_height);
    [_delegate volumeDidChanged:result];
    //NSLog(@"result = %f",result);
                        
}

- (void)pause {
    [self.recorder pause];
    [_timer invalidate];
}

- (void)record {
    [self.recorder record];
    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.06 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
    
}


#pragma mark - private
- (void)configSelf {
    //

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //[audioSession setCategory: AVAudioSessionCategoryAmbient error: nil];
    [audioSession setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    //
//    [audioSession requestRecordPermission:^(BOOL granted) {
//        if (granted) {
//            [self.recorder record];
//            _timer = [NSTimer scheduledTimerWithTimeInterval: 0.06 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
//        }
//        else {
//            NSLog(@"world");
//        }
//    }];
}

#pragma mark - getter
- (AVAudioRecorder *)recorder {
    if (!_recorder) {
        NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
        NSLog(@"%@",url);
        NSDictionary *settings = @{AVSampleRateKey: @44100.0, AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatAppleLossless], AVNumberOfChannelsKey: @2, AVEncoderAudioQualityKey: [NSNumber numberWithInt:AVAudioQualityMax]};
        _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:nil];
        [_recorder prepareToRecord];
        _recorder.meteringEnabled = YES;
    }
    return _recorder;
}



















@end
