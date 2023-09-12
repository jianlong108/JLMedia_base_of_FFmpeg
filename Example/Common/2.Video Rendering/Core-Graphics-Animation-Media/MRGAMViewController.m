//
//  MRGAMViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2022/11/22.
//  Copyright © 2022 Matt Reach's Awesome FFmpeg Tutotial. All rights reserved.
//

#import "MRGAMViewController.h"
#import <FFmpegTutorial/FFTPlayer0x03.h>
#import <FFmpegTutorial/FFTHudControl.h>
#import <libavutil/frame.h>
#import "MRCoreAnimationView.h"
#import "MRCoreGraphicsView.h"
#import "MRCoreMediaView.h"
#import "MRRWeakProxy.h"
#import "MRUtil.h"
#import "MRDragView.h"

#define DEBUG_RECORD_YUV_TO_FILE 1

#if DEBUG_RECORD_YUV_TO_FILE
#import <libavutil/imgutils.h>

uint8_t *_imgBuf[4] = {NULL};
int _lineSize[4] = {0};
int imgSize = 0;
#endif

@interface MRGAMViewController ()
<
#if TARGET_OS_OSX
MRDragViewDelegate,
#endif
FFTPlayer0x03Delegate
>
{
    MRPixelFormatMask _pixelFormat;
    FILE * file_yuv;
}

@property (strong) FFTPlayer0x03 *player;

@property (weak) NSView<MRVideoRenderingProtocol>* videoRenderer;
@property (assign) Class<MRVideoRenderingProtocol> renderingClazz;
@property (nonatomic, strong) NSTextField *inputField;
@property (nonatomic, strong) NSProgressIndicator *indicatorView;
@property (nonatomic, strong) NSView *playbackView;

@property (nonatomic, strong) NSArray <NSURL *>* urlArr;
#if TARGET_OS_OSX
@property (nonatomic, strong) NSPopUpButton *formatPopup;
@property (nonatomic, strong) NSPopUpButton *renderModePopup;
@property (nonatomic, strong) NSPopUpButton *colorSpacePopup;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) MRDragView *dragView;
#else
@property (nonatomic, strong) MRSegmentedControl *formatSegCtrl;
#endif
@property (nonatomic, strong) FFTHudControl *hud;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) NSString *videoPixelInfo;

@end

@implementation MRGAMViewController

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

#if DEBUG_RECORD_YUV_TO_FILE
    if (_imgBuf[0]) {
        av_freep(_imgBuf[0]);
    }
#endif
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
    
    NSString *renderer = NSStringFromClass([self.videoRenderer class]);
    renderer = [renderer stringByReplacingOccurrencesOfString:@"MR" withString:@""];
    renderer = [renderer stringByReplacingOccurrencesOfString:@"View" withString:@""];
    [self.hud setHudValue:renderer forKey:@"renderer"];
}

- (void)alert:(NSString *)msg
{
    [self alert:@"知道了" msg:msg];
}

- (void)displayVideoFrame:(AVFrame *)frame
{
    const char *fmt_str = av_pixel_fmt_to_string(frame->format);
    self.videoPixelInfo = [NSString stringWithFormat:@"%s_%dx%d",fmt_str,frame->width,frame->height];
    [self.videoRenderer displayAVFrame:frame];

#if DEBUG_RECORD_YUV_TO_FILE
    if (file_yuv == NULL) {
        NSString *fileName = [NSString stringWithFormat:@"%@.yuv",self.videoPixelInfo];
        const char *l = [[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] UTF8String];
        NSLog(@"create file:%s",l);
        file_yuv = fopen(l, "wb+");
    }
    if (imgSize == 0) {
        imgSize = av_image_alloc(_imgBuf,_lineSize,frame->width,frame->height,frame->format,1);
    }
    av_image_copy(_imgBuf,_lineSize,(const uint8_t **)frame->data,frame->linesize,frame->format,frame->width,frame->height);
    //ffmpeg -hide_banner -formats | grep PCM
    //ffmpeg -hide_banner -pix_fmts | grep rgb
    //播放验证: ffplay -pixel_format rgba -video_size 576x1024 -i /var/folders/34/4vwcpjcs3pj3z6ys4b2b181r0000gn/T/debugly.cn.FFmpegTutorial-macOS/RGBA_576x1024.yuv
    fwrite(_imgBuf[0], imgSize, 1, file_yuv);
#endif
}

- (void)setupCoreAnimationPixelFormats
{
    NSArray *fmts = @[@"RGBA",@"RGB0",@"ARGB",@"0RGB",@"RGB24",@"RGB555"];
    NSArray *tags = @[@(MR_PIX_FMT_MASK_RGBA),@(MR_PIX_FMT_MASK_RGB0),@(MR_PIX_FMT_MASK_ARGB),@(MR_PIX_FMT_MASK_0RGB),@(MR_PIX_FMT_MASK_RGB24),@(MR_PIX_FMT_MASK_RGB555)];
    
#if TARGET_OS_OSX
    [self.formatPopup removeAllItems];
    [self.formatPopup addItemsWithTitles:fmts];
    for (int i = 0; i < [[self.formatPopup itemArray] count]; i++) {
        NSMenuItem * item = [self.formatPopup itemAtIndex:i];
        item.tag = [tags[i] intValue];
    }
#else
    [self.formatSegCtrl removeAllSegments];
    for (int i = 0; i < [fmts count]; i++) {
        NSString *title = fmts[i];
        [self.formatSegCtrl insertSegmentWithTitle:title atIndex:i animated:NO tag:[tags[i] intValue]];
    }
    self.formatSegCtrl.selectedSegmentIndex = 0;
#endif
    _pixelFormat = [[tags firstObject] intValue];
}

- (void)setupCoreGraphicsPixelFormats
{
    [self setupCoreAnimationPixelFormats];
}

- (void)setupCoreMediaPixelFormats
{
    NSArray *fmts = @[@"BGRA",@"ARGB",@"NV12",@"YUYV",@"UYVY"];
    NSArray *tags = @[@(MR_PIX_FMT_MASK_BGRA),@(MR_PIX_FMT_MASK_ARGB),@(MR_PIX_FMT_MASK_NV12),@(MR_PIX_FMT_MASK_YUYV422),@(MR_PIX_FMT_MASK_UYVY422)];
#if TARGET_OS_OSX
    [self.formatPopup removeAllItems];
    [self.formatPopup addItemsWithTitles:fmts];
    for (int i = 0; i < [[self.formatPopup itemArray] count]; i++) {
        NSMenuItem * item = [self.formatPopup itemAtIndex:i];
        item.tag = [tags[i] intValue];
    }
#else
    [self.formatSegCtrl removeAllSegments];
    for (int i = 0; i < [fmts count]; i++) {
        NSString *title = fmts[i];
        [self.formatSegCtrl insertSegmentWithTitle:title atIndex:i animated:NO tag:[tags[i] intValue]];
    }
    self.formatSegCtrl.selectedSegmentIndex = 0;
#endif
    _pixelFormat = [[tags firstObject] intValue];
}

#pragma - mark actions


- (BOOL)prepareRendererWidthClass:(Class)clazz
{
    if (self.videoRenderer && [self.videoRenderer isKindOfClass:clazz]) {
        return NO;
    }
    [self.videoRenderer removeFromSuperview];
    self.videoRenderer = nil;
    
    NSView<MRVideoRenderingProtocol> *videoRenderer = [[clazz alloc] initWithFrame:self.playbackView.bounds];
    [self.playbackView addSubview:videoRenderer];
#if TARGET_OS_OSX
    [self.playbackView addSubview:videoRenderer positioned:NSWindowBelow relativeTo:nil];
#endif
    videoRenderer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.videoRenderer = videoRenderer;
    return YES;
}

- (BOOL)prepareCoreAnimationView
{
    if (self.renderingClazz != [MRCoreAnimationView class]) {
        [self setupCoreAnimationPixelFormats];
        self.renderingClazz = [MRCoreAnimationView class];
        return YES;
    }
    return NO;
}

- (BOOL)prepareCoreGraphicsView
{
    if (self.renderingClazz != [MRCoreGraphicsView class]) {
        [self setupCoreGraphicsPixelFormats];
        self.renderingClazz = [MRCoreGraphicsView class];
        return YES;
    }
    return NO;
}

- (BOOL)prepareCoreMediaView
{
    if (self.renderingClazz != [MRCoreMediaView class]) {
        [self setupCoreMediaPixelFormats];
        self.renderingClazz = [MRCoreMediaView class];
        return YES;
    }
    return NO;
}

- (void)doSelectedVideoRenderer:(int)tag
{
    BOOL created = NO;
    if (tag == 1) {
        created = [self prepareCoreAnimationView];
    } else if (tag == 2) {
        created = [self prepareCoreGraphicsView];
    } else if (tag == 3) {
        created = [self prepareCoreMediaView];
    }
    
    if (created) {
        [self go:nil];
    }
}

- (void)doSelectedVideMode:(int)tag
{
    if (tag == 1) {
        [self.videoRenderer setRenderingMode:MRRenderingModeScaleToFill];
    } else if (tag == 2) {
        [self.videoRenderer setRenderingMode:MRRenderingModeScaleAspectFill];
    } else if (tag == 3) {
        [self.videoRenderer setRenderingMode:MRRenderingModeScaleAspectFit];
    }
}

- (void)doSelectPixelFormat:(MRPixelFormatMask)fmt
{
    if (_pixelFormat != fmt) {
        _pixelFormat = fmt;
        [self go:nil];
    }
}

#if TARGET_OS_OSX
- (IBAction)onSelectedVideoRenderer:(NSPopUpButton *)sender
{
    NSMenuItem *item = [sender selectedItem];
    [self doSelectedVideoRenderer:(int)item.tag];
}

- (IBAction)onSelectedVideMode:(NSPopUpButton *)sender
{
    NSMenuItem *item = [sender selectedItem];
    [self doSelectedVideMode:(int)item.tag];
}

- (IBAction)onSelectPixelFormat:(NSPopUpButton *)sender
{
    NSMenuItem *item = [sender selectedItem];
    [self doSelectPixelFormat:(MRPixelFormatMask)item.tag];
}
#else

- (void)onSelectedVideoRenderer:(MRSegmentedControl *)sender
{
    [self doSelectedVideoRenderer:(int)[sender tagForCurrentSelected] + 1];
}

- (void)onSelectedVideMode:(MRSegmentedControl *)sender
{
    [self doSelectedVideMode:(int)[sender tagForCurrentSelected] + 1];
}

- (void)onSelectPixelFormat:(MRSegmentedControl *)sender
{
    [self doSelectPixelFormat:(MRPixelFormatMask)[sender tagForCurrentSelected]];
}

#endif


#if TARGET_OS_OSX
- (void)loadView
{
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, [MRUtil windowMinSize].width, [MRUtil windowMinSize].height)];
}

- (NSTextView *)textView {
    if(!_textView) {
        _textView = [[NSTextView alloc] init];
        _textView.backgroundColor = [NSColor textBackgroundColor];
        _textView.editable = NO;
        _textView.textColor = [NSColor textColor];

        //NSScrollView
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        [_textView setMinSize:NSMakeSize(0.0, self.view.frame.size.height - 80)];
        [_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [_textView setVerticallyResizable:YES];//垂直方向可以调整大小
        [_textView setHorizontallyResizable:NO];//水平方向不可以调整大小
        [_textView setAutoresizingMask:NSViewWidthSizable];
        [[_textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [[_textView textContainer] setWidthTracksTextView:YES];
        [_textView setFont:[NSFont fontWithName:@"PingFang-SC-Regular" size:18.0]];
        [_textView setEditable:NO];

        [scrollView setDocumentView:_textView];
        [self.view addSubview:scrollView];
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(44);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
    }
    return _textView;
}
#endif
- (void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_OS_OSX
    NSTextField *fieldTitle = [[NSTextField alloc] init];
    fieldTitle.editable = NO;
    fieldTitle.backgroundColor = [NSColor blackColor];
    fieldTitle.stringValue = @"媒体url:";

    self.inputField = [[NSTextField alloc] init];


    NSButton *goBtn = [NSButton buttonWithTitle:@"查看" target:self action:@selector(go:)];

    self.renderModePopup = [[NSPopUpButton alloc] init];
    [self.renderModePopup addItemsWithTitles:@[@"Scale To Fill",@"Scale Aspect Fill",@"Scale Aspect Fit"]];
    self.renderModePopup.target = self;
    self.renderModePopup.action = @selector(onSelectedVideoRenderer:);
    self.formatPopup = [[NSPopUpButton alloc] init];
    self.formatPopup.target = self;
    self.formatPopup.action = @selector(onSelectPixelFormat:);

    NSStackView *stackView = [[NSStackView alloc] init];
    stackView.spacing = 5.f;
    [self.view addSubview:stackView];
    [stackView addArrangedSubview:fieldTitle];
    [stackView addArrangedSubview:self.inputField];
    [stackView addArrangedSubview:goBtn];
    [stackView addArrangedSubview:self.renderModePopup];

    [stackView addArrangedSubview:self.formatPopup];
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];

    MRDragView *dragView = [[MRDragView alloc ] init];
    dragView.delegate = self;
    [self.view addSubview:dragView];
    [dragView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.inputField.stringValue = KTestVideoURL1;

    self.textView.string = @"可拖拽视频文件查看视频信息";

#else

#endif

    self.hud = [[FFTHudControl alloc] init];
    NSView *hudView = [self.hud contentView];
    [self.playbackView addSubview:hudView];
    hudView.layer.zPosition = 100;
    CGRect rect = self.playbackView.bounds;
#if TARGET_OS_IPHONE
    rect.size.width = 300;
#else
    CGFloat screenWidth = [[NSScreen mainScreen]frame].size.width;
    rect.size.width = MIN(screenWidth / 5.0, 150);
#endif
    rect.origin.x = CGRectGetWidth(self.view.bounds) - rect.size.width;
    [hudView setFrame:rect];

    hudView.autoresizingMask = NSViewMinXMargin | NSViewHeightSizable;

    self.inputField.stringValue = KTestVideoURL1;
    self.playbackView = [[NSView alloc] init];
    self.playbackView.wantsLayer = YES;
    self.playbackView.layer.backgroundColor = [NSColor redColor].CGColor;
    [self.view addSubview:self.playbackView];
    [self.playbackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(320,240));
    }];
    [self prepareCoreAnimationView];
}


- (void)viewWillDisappear
{
    [super viewWillDisappear];
    if (_player) {
        [_player asyncStop];
        _player = nil;
    }
}
#pragma mark - action
- (void)go:(NSButton *)sender
{
#if TARGET_OS_OSX
    [self fetchFirstURL];
#endif
    if (self.inputField.stringValue.length > 0) {
        [self parseURL:self.inputField.stringValue];
    } else {
        self.inputField.placeholderString = @"请输入视频地址";
    }
}

- (void)parseURL:(NSString *)url
{
    if (self.player) {
        [self.player asyncStop];
        self.player = nil;

        [self.timer invalidate];
        self.timer = nil;
    }

    FFTPlayer0x03 *player = [[FFTPlayer0x03 alloc] init];
    player.delegate = self;
    player.contentPath = url;
    player.supportedPixelFormats = _pixelFormat;
    [player prepareToPlay];
    [player play];
    self.player = player;

    [self prepareTickTimerIfNeed];
    [self.indicatorView startAnimation:nil];
}
#pragma mark - FFTPlayer0x03Delegate

- (void)player:(FFTPlayer0x03 *)player receiveMediaStream:(NSString *)info pixWidth:(CGFloat)w pixHeight:(CGFloat)h {
    if (player != self.player) {
        return;
    }
    [self prepareRendererWidthClass:self.renderingClazz];
    [self.indicatorView stopAnimation:nil];
    NSLog(@"---VideoInfo-------------------");
    NSLog(@"w:%f h:%f",w,h);
    NSLog(@"----------------------");
}
// call frequently
- (void)player:(FFTPlayer0x03 *)player whenReadPacket:(int)audioPacketCount videoPacketCount:(int)videoPacketCount {

}
// call frequently
- (void)player:(FFTPlayer0x03 *)player whenDecodeFrameType:(int)frameType frameCount:(int)count frame:(AVFrame *)frame {
    if (player != self.player) {
        return;
    }
    //video
    if (frameType == 1) {
        @autoreleasepool {
            [self displayVideoFrame:frame];
        }
        mr_msleep(40);
    }
    //frameType
    else if (frameType == 2) {
    }
}


- (void)player:(FFTPlayer0x03 *)player occureError:(NSError *)error
{
    if (player != self.player) {
        return;
    }
    [self.indicatorView stopAnimation:nil];
    [self alert:[self.player.error localizedDescription]];
    self.player = nil;
    [self.timer invalidate];
    self.timer = nil;
}

#if TARGET_OS_OSX
#pragma mark --拖拽的代理方法

- (NSDragOperation)acceptDragOperation:(NSArray<NSURL *> *)list
{
    for (NSURL *url in list) {
        if (url) {
            //先判断是不是文件夹
            BOOL isDirectory = NO;
            BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
            if (isExist) {
                if (isDirectory) {
                   //扫描文件夹
                   NSString *dir = [url path];
                   NSArray *dicArr = [MRUtil scanFolderWithPath:dir filter:[MRUtil videoType]];
                    if ([dicArr count] > 0) {
                        return NSDragOperationCopy;
                    }
                } else {
                    NSString *pathExtension = [[url pathExtension] lowercaseString];
                    if ([[MRUtil videoType] containsObject:pathExtension]) {
                        return NSDragOperationCopy;
                    }
                }
            }
        }
    }
    return NSDragOperationNone;
}

- (void)fetchFirstURL
{
    NSString *path = nil;
    NSMutableArray *urlArr = [NSMutableArray arrayWithArray:self.urlArr];
    NSURL *url = [urlArr firstObject];
    if ([url isFileURL]) {
        path = [url path];
    } else {
        path = [url absoluteString];
    }
    if ([urlArr count] > 0) {
        [urlArr removeObjectAtIndex:0];
    }
    self.urlArr = [urlArr copy];

    if (path) {
        self.inputField.stringValue = path;
    }
}

- (void)handleDragFileList:(NSArray <NSURL *> *)fileUrls
{
    NSMutableArray *bookmarkArr = [NSMutableArray array];

    for (NSURL *url in fileUrls) {
        //先判断是不是文件夹
        BOOL isDirectory = NO;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
        if (isExist) {
            if (isDirectory) {
                //扫描文件夹
                NSString *dir = [url path];
                NSArray *dicArr = [MRUtil scanFolderWithPath:dir filter:[MRUtil videoType]];
                if ([dicArr count] > 0) {
                    [bookmarkArr addObjectsFromArray:dicArr];
                }
            } else {
                NSString *pathExtension = [[url pathExtension] lowercaseString];
                if ([[MRUtil videoType] containsObject:pathExtension]) {
                    //视频
                    NSDictionary *dic = [MRUtil makeBookmarkWithURL:url];
                    [bookmarkArr addObject:dic];
                }
            }
        }
    }

    NSMutableArray *urls = [NSMutableArray array];

    for (int i = 0; i < [bookmarkArr count]; i++) {
        NSDictionary *info = bookmarkArr[i];
        NSURL *url = info[@"url"];
        //NSData *bookmark = info[@"bookmark"];
        if (url) {
            [urls addObject:url];
        }
    }

    NSMutableArray *urlArr = [NSMutableArray arrayWithArray:self.urlArr];
    [urlArr addObjectsFromArray:urls];
    self.urlArr = [urlArr copy];

    [self go:nil];
}
#endif

@end
