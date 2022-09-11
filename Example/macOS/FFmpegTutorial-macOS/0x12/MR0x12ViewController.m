//
//  MR0x12ViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2021/7/9.
//  Copyright © 2021 Matt Reach's Awesome FFmpeg Tutotial. All rights reserved.
//

#import "MR0x12ViewController.h"
#import <FFmpegTutorial/FFPlayer0x10.h>
#import <FFmpegTutorial/MRHudControl.h>
#import <FFmpegTutorial/MRConvertUtil.h>
#import <FFmpegTutorial/MRDispatch.h>
#import "MR0x12VideoRenderer.h"
#import "MRRWeakProxy.h"

@interface MR0x12ViewController ()

@property (strong) FFPlayer0x10 *player;
@property (weak) IBOutlet NSTextField *inputField;
@property (weak) IBOutlet NSProgressIndicator *indicatorView;
@property (weak) IBOutlet MR0x12VideoRenderer *videoRenderer;

@property (strong) MRHudControl *hud;
@property (weak) NSTimer *timer;

@end

@implementation MR0x12ViewController

- (void)dealloc
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
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

- (void)displayVideoFrame:(AVFrame *)frame
{
    CGImageRef cgImage = [MRConvertUtil cgImageFromRGBFrame:frame];
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    NSImage *img = [[NSImage alloc] initWithCGImage:cgImage size:CGSizeMake(width, height)];
    mr_sync_main_queue(^{
        self.videoRenderer.image = img;
    });
}

- (void)parseURL:(NSString *)url
{
    if (self.player) {
        [self.player asyncStop];
        self.player = nil;
        [self.timer invalidate];
        self.timer = nil;
        [self.hud destroyContentView];
        self.hud = nil;
    }
    
    self.hud = [[MRHudControl alloc] init];
    NSView *hudView = [self.hud contentView];
    [self.videoRenderer addSubview:hudView];
    CGRect rect = self.videoRenderer.bounds;
    CGFloat screenWidth = [[NSScreen mainScreen]frame].size.width;
    rect.size.width = MIN(screenWidth / 5.0, 150);
    rect.origin.x = CGRectGetWidth(self.view.bounds) - rect.size.width;
    [hudView setFrame:rect];
    hudView.autoresizingMask = NSViewMinXMargin | NSViewHeightSizable;
    
    [self.indicatorView startAnimation:nil];
    
    FFPlayer0x10 *player = [[FFPlayer0x10 alloc] init];
    player.contentPath = url;
    player.supportedPixelFormats = MR_PIX_FMT_MASK_RGBA;
    
    __weakSelf__
    player.onError = ^(NSError * _Nonnull e) {
        __strongSelf__
        [self.indicatorView stopAnimation:nil];
        [self alert:[self.player.error localizedDescription]];
        self.player = nil;
        [self.timer invalidate];
        self.timer = nil;
    };
    
    player.onDecoderFrame = ^(int type, int serial, AVFrame * _Nonnull frame) {
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
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    [self.player asyncStop];
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
