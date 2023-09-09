//
//  MRCustomDecoderViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2021/4/15.
//  Copyright © 2021 Matt Reach's Awesome FFmpeg Tutotial. All rights reserved.
//

#import "MRCustomDecoderViewController.h"
#import <FFmpegTutorial/FFTPlayer0x02.h>
#if TARGET_OS_OSX
#import "MRDragView.h"
#import "MRUtil.h"
#endif
#import "FFTDispatch.h"

@interface MRCustomDecoderViewController ()<
FFTPlayer0x02Delegate
#if TARGET_OS_OSX
,MRDragViewDelegate
#endif
>

@property (nonatomic, strong) FFTPlayer0x02 *player;
@property (nonatomic, strong) NSTextField *inputField;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSProgressIndicator *indicatorView;
@property (nonatomic, strong) NSArray <NSURL *>* urlArr;


#if TARGET_OS_IPHONE
@property (nonatomic, strong) UILabel *audioPktLb;
@property (nonatomic, strong) UILabel *videoPktLb;
#else
@property (nonatomic, strong) NSText *audioPktLb;
@property (nonatomic, strong) NSText *videoPktLb;
@property (nonatomic, strong) NSText *audioFrmLb;
@property (nonatomic, strong) NSText *videoFrmLb;
#endif

@end

@implementation MRCustomDecoderViewController

- (void)dealloc {
}
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

    NSStackView *stackView = [[NSStackView alloc] init];
    stackView.spacing = 5.f;
    [self.view addSubview:stackView];
    [stackView addArrangedSubview:fieldTitle];
    [stackView addArrangedSubview:self.inputField];
    [stackView addArrangedSubview:goBtn];
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

    self.audioPktLb = [[NSText alloc ] init];

    self.audioPktLb.backgroundColor = [NSColor orangeColor];
    [self.view addSubview:self.audioPktLb];
    [self.audioPktLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(200,20));
    }];
    self.videoPktLb = [[NSText alloc ] init];
    self.videoPktLb.backgroundColor = [NSColor blueColor];
    [self.view addSubview:self.videoPktLb];
    [self.videoPktLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.audioPktLb.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(200,20));
    }];
    self.audioFrmLb = [[NSText alloc ] init];
    self.audioFrmLb.backgroundColor = [NSColor brownColor];
    [self.view addSubview:self.audioFrmLb];
    [self.audioFrmLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.videoPktLb.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(200,20));
    }];
    self.videoFrmLb = [[NSText alloc ] init];
    self.videoFrmLb.backgroundColor = [NSColor purpleColor];
    [self.view addSubview:self.videoFrmLb];
    [self.videoFrmLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.audioFrmLb.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(200,20));
    }];
#else
    
#endif
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
    [self.indicatorView startAnimation:nil];
    if (self.player) {
        [self.player asyncStop];
    }

    FFTPlayer0x02 *player = [[FFTPlayer0x02 alloc] init];
    player.delegate = self;
    player.contentPath = url;
    [player prepareToPlay];
    self.player = player;
    [self.player play];
}
#pragma mark - FFTPlayer0x02Delegate
- (void)player:(FFTPlayer0x02 *)player receiveMediaStream:(NSString *)info
{
    self.textView.string = info;
    [self.player asyncStop];
    self.player = nil;
}

- (void)player:(FFTPlayer0x02 *)player occureError:(NSError *)error
{
    self.textView.string = [error localizedDescription];
}


- (void)player:(FFTPlayer0x02 *)player whenReadPacket:(int)audioPacketCount videoPacketCount:(int)videoPacketCount {
    mr_async_main_queue(^{
#if TARGET_OS_OSX
        self.audioPktLb.string = [NSString stringWithFormat:@"audioPacket:%d",audioPacketCount];
        self.videoPktLb.string = [NSString stringWithFormat:@"videoPacket:%d",videoPacketCount];
#else

#endif
    });
}

- (void)player:(FFTPlayer0x02 *)player whenDecodeFrame:(int)audioFrame videoFrameCount:(int)videoFrameCount {
    mr_async_main_queue(^{
#if TARGET_OS_OSX
        self.audioFrmLb.string = [NSString stringWithFormat:@"audioFrameCount:%d",audioFrame];
        self.videoFrmLb.string = [NSString stringWithFormat:@"videoFrameCount:%d",videoFrameCount];
#else

#endif
    });
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
