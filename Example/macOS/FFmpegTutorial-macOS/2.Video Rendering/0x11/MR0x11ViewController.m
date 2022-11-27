//
//  MR0x11ViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2021/4/15.
//  Copyright © 2021 Matt Reach's Awesome FFmpeg Tutotial. All rights reserved.
//

#import "MR0x11ViewController.h"
#import <FFmpegTutorial/FFTPlayer0x10.h>
#import <FFmpegTutorial/FFTHudControl.h>
#import <FFmpegTutorial/FFTConvertUtil.h>
#import <FFmpegTutorial/FFTDispatch.h>
#import <MRFFmpegPod/libavutil/frame.h>
#import "MR0x11VideoRenderer.h"
#import "MRRWeakProxy.h"

@interface MR0x11ViewController ()

@property (strong) FFTPlayer0x10 *player;
@property (weak) IBOutlet NSTextField *inputField;
@property (weak) IBOutlet MR0x11VideoRenderer *videoRenderer;
@property (weak) IBOutlet NSProgressIndicator *indicatorView;

@property (strong) FFTHudControl *hud;
@property (weak) NSTimer *timer;
@property (copy) NSString *videoPixelInfo;

@end

@implementation MR0x11ViewController

- (void)dealloc
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (_player) {
        [_player asyncStop];
        _player = nil;
    }
}

- (void)prepareTickTimerIfNeed
{
    if (self.timer && ![self.timer isValid]) {
        return;
    }
    MRRWeakProxy *weakProxy = [MRRWeakProxy weakProxyWithTarget:self];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:weakProxy selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
}

- (void)onTimer:(NSTimer *)sender
{
    [self.indicatorView stopAnimation:nil];
    
    [self.hud setHudValue:[NSString stringWithFormat:@"%02d",self.player.audioFrameCount] forKey:@"a-frame"];
    
    [self.hud setHudValue:[NSString stringWithFormat:@"%02d",self.player.videoFrameCount] forKey:@"v-frame"];
    
    [self.hud setHudValue:[NSString stringWithFormat:@"%02d",self.player.audioPktCount] forKey:@"a-pack"];

    [self.hud setHudValue:[NSString stringWithFormat:@"%02d",self.player.videoPktCount] forKey:@"v-pack"];
    
    [self.hud setHudValue:[NSString stringWithFormat:@"%@",self.videoPixelInfo] forKey:@"v-pixel"];
}

- (void)alert:(NSString *)msg
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"知道了"];
    [alert setMessageText:@"错误提示"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSInformationalAlertStyle];
    NSModalResponse returnCode = [alert runModal];
    
    if (returnCode == NSAlertFirstButtonReturn)
    {
        //nothing todo
    }
    else if (returnCode == NSAlertSecondButtonReturn)
    {
        
    }
}

- (void)parseURL:(NSString *)url
{
    if (self.player) {
        [self.player asyncStop];
        self.player = nil;
    }
    
    [self.indicatorView startAnimation:nil];
    
    FFTPlayer0x10 *player = [[FFTPlayer0x10 alloc] init];
    player.contentPath = url;
    player.supportedPixelFormats =
    MR_PIX_FMT_MASK_RGBA;// |
//    MR_PIX_FMT_MASK_ARGB |
//    MR_PIX_FMT_MASK_0RGB |
//    MR_PIX_FMT_MASK_RGB24;
    
    __weakSelf__
    player.onError = ^(FFTPlayer0x10 *player,NSError *err){
        __strongSelf__
        [self.indicatorView stopAnimation:nil];
        [self alert:[self.player.error localizedDescription]];
        self.player = nil;
        [self.timer invalidate];
        self.timer = nil;
    };
    
    player.onDecoderFrame = ^(FFTPlayer0x10 *player,int type,int serial,AVFrame *frame) {
        __strongSelf__
        //video
        if (type == 1) {
            mr_msleep(40);
            @autoreleasepool {
                [self displayVideoFrame:frame];
            }
        }
        //audio
        else if (type == 2) {
            
        }
    };
    
    [player prepareToPlay];
    [player play];
    self.player = player;
    [self prepareTickTimerIfNeed];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.inputField.stringValue = KTestVideoURL1;
    
    self.hud = [[FFTHudControl alloc] init];
    NSView *hudView = [self.hud contentView];
    [self.videoRenderer addSubview:hudView];
    CGRect rect = self.videoRenderer.bounds;
    CGFloat screenWidth = [[NSScreen mainScreen]frame].size.width;
    rect.size.width = MIN(screenWidth / 5.0, 150);
    rect.origin.x = CGRectGetWidth(self.view.bounds) - rect.size.width;
    [hudView setFrame:rect];
    hudView.autoresizingMask = NSViewMinXMargin | NSViewHeightSizable;
}

- (void)displayVideoFrame:(AVFrame *)frame
{
    const char *fmt_str = av_pixel_fmt_to_string(frame->format);
    self.videoPixelInfo = [NSString stringWithFormat:@"(%s)%dx%d",fmt_str,frame->width,frame->height];

    CGImageRef img = [FFTConvertUtil cgImageFromRGBFrame:frame];
    mr_sync_main_queue(^{
        [self.videoRenderer dispalyCGImage:img];
    });
}

#pragma - mark actions

- (IBAction)go:(NSButton *)sender
{
    if (self.inputField.stringValue.length > 0) {
        [self parseURL:self.inputField.stringValue];
    } else {
        self.inputField.placeholderString = @"请输入视频地址";
    }
}

@end
