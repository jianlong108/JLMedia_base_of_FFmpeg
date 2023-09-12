//
//  MRGLVersionViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2021/4/14.
//  Copyright © 2021 Matt Reach's Awesome FFmpeg Tutotial. All rights reserved.
//

#import "MRGLVersionViewController.h"
#import <FFmpegTutorial/FFTVersionHelper.h>
#if TARGET_OS_OSX
#import <FFmpegTutorial/FFTOpenGLVersionHelper.h>
#import "MRUtil.h"
#endif

@interface MRGLVersionViewController ()
#if TARGET_OS_OSX
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;
#else

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIScrollView *scrollView;
#endif
@end

@implementation MRGLVersionViewController
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
            make.top.equalTo(self.view).offset(0);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
    }
    return _textView;
}

#endif
- (void)viewDidLoad {
    [super viewDidLoad];
    __block NSString *info = [FFTVersionHelper ffmpegAllInfo];
#if TARGET_OS_OSX
    [FFTOpenGLVersionHelper prepareOpenGLContext:^{
        info = [info stringByAppendingString:[FFTOpenGLVersionHelper openglAllInfo:NO]];
    } forLegacy:NO];
    
    [FFTOpenGLVersionHelper prepareOpenGLContext:^{
        info = [info stringByAppendingString:[FFTOpenGLVersionHelper openglAllInfo:YES]];
    } forLegacy:YES];
    self.textView.string = info;
#else
    self.textView = [[UITextView alloc] init];
    [self.view addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    self.textView.text = info;
#endif
}

@end
