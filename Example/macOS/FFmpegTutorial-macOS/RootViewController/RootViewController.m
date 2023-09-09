//
//  RootViewController.m
//  FFmpegTutorial-macOS
//
//  Created by qianlongxu on 2020/11/25.
//

#import "RootViewController.h"
#import "RootTableRowView.h"
#import "NSNavigationController.h"
#import "MRUtil.h"

@interface RootViewController ()<NSTableViewDelegate,NSTableViewDataSource>

@property(nonatomic, strong) NSTableView *tableView;
@property(nonatomic, strong) NSArray *dataArr;

@end

@implementation RootViewController

//-[NSNib _initWithNibNamed:bundle:options:] could not load the nibName: RootViewController in bundle (null).
- (void)loadView
{
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.title = @"Media-Tutorial";
    
    NSScrollView * scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = NO;
    scrollView.hasHorizontalScroller = NO;
    scrollView.frame = self.view.bounds;
    scrollView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    [self.view addSubview:scrollView];
    
    NSTableView *tableView = [[NSTableView alloc] initWithFrame:self.view.bounds];
    tableView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    tableView.intercellSpacing = NSMakeSize(0, 0);
    if ([MRUtil isDarkMode]) {
        tableView.backgroundColor = [NSColor blackColor];
    } else {
        tableView.backgroundColor = [NSColor colorWithWhite:230.0/255.0 alpha:1.0];
    }
   
//    if (@available(macOS 11.0, *)) {
//        tableView.style = NSTableViewStylePlain;
//    } else {
//        // Fallback on earlier versions
//    }
    //设置选中行背景样式，设置成None时drawSelectionInRect就不走了;
    tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
//    NSTableColumn *column = [[NSTableColumn alloc] init];
//    column.title = @"我的FFmpeg学习教程";
//    column.editable = NO;
//    column.width = CGRectGetWidth(self.view.bounds);
//    column.resizingMask = NSTableColumnAutoresizingMask;
//    [tableView addTableColumn:column];
    //隐藏掉列Header
    tableView.headerView = nil;
    //开启后，不能覆盖drawBackgroundInRect否则无效
    tableView.usesAlternatingRowBackgroundColors = NO;
    //横实线
    //tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    //tableView.gridStyleMask = NSTableViewSolidVerticalGridLineMask;

    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowSizeStyle = NSTableViewRowSizeStyleCustom;
    scrollView.contentView.documentView = tableView;
    
    self.dataArr = @[
        @{
            @"isSeparactor":@(YES),
            @"height":@(1.0)
        },
        @{
            @"title":@"一、播放器",
            @"isSection":@(YES)
        },
        @{
            @"title":@"1.1:OpenGL/FFMpeg Version",
            @"detail":@"FFmpeg编译配置和版本信息;OpengGL信息",
            @"class":@"MRGLVersionViewController",
        },
        @{
            @"title":@"1.2:Movie Prober",
            @"detail":@"查看媒体流信息/读媒体包",
            @"class":@"MRMovieProberViewController",
        },
        @{
            @"title":@"1.3:Decode Packet",
            @"detail":@"音视频解码/封装解码类",
            @"class":@"MRCustomDecoderViewController",
        },
        @{
            @"title":@"1.4:Core Animation/Core Graphics/Core Media",
            @"detail":@"渲染 xRGBx / xRGBx / NV12,YUYV,UYVY 视频桢",
            @"class":@"MRGAMViewController",
        },
        @{
            @"title":@"1.5:Legacy OpenGL",
            @"detail":@"渲染 BGRA/NV12/NV21/YUV420P/UYVY/YUYV 视频桢",
            @"class":@"MRLegacyGLViewController",
        },
        @{
            @"title":@"1.6:Modern OpenGL",
            @"detail":@"渲染 BGRA/NV12/NV21/YUV420P/UYVY/YUYV 视频桢",
            @"class":@"MRModernGLViewController",
        },
        @{
            @"title":@"1.7:Modern OpenGL(Rectangle Texture)",
            @"detail":@"渲染 BGRA/NV12/NV21/YUV420P/UYVY/YUYV 视频桢",
            @"class":@"MRModernGLRectViewController",
        },
        @{
            @"title":@"1.8:Metal",
            @"detail":@"渲染 BGRA/NV12/NV21/YUV420P/UYVY/YUYV 视频桢",
            @"class":@"MRMetalViewController",
        },
        @{
            @"title":@"1.9:AudioUnit",
            @"detail":@"支持 S16,S16P,Float,FloatP 格式，采样率为 44.1K,48K,96K,192K",
            @"class":@"MRAudioUnitViewController",
        },
        @{
            @"title":@"1.10:AudioQueue",
            @"detail":@"支持 S16,Float 格式，采样率为 44.1K,48K,96K,192K",
            @"class":@"MRAudioQueueViewController",
        },
        @{
            @"title":@"1.11:封装AudioUnit 和 AudioQueue",
            @"detail":@"支持 S16,S16P,Float,FloatP 格式，采样率为 44.1K,48K,96K,192K",
            @"class":@"MRAudioRendererViewController",
        },
        @{
            @"title":@"四、封装播放器",
            @"isSection":@(YES)
        },
        @{
            @"title":@"VideoFrameQueue",
            @"detail":@"增加 VideoFrame 缓存队列，不阻塞解码线程",
            @"class":@"MRVideoFrameQueueViewController",
        },
        @{
            @"title":@"PacketQueue",
            @"detail":@"增加 AVPacket 缓存队列，创建解码线程",
            @"class":@"MRPacketQueueViewController",
        },
        @{
            @"title":@"0x32",
            @"detail":@"创建视频渲染线程，将视频相关逻辑封装到播放器内",
            @"class":@"MR0x32ViewController",
        },
        @{
            @"title":@"0x33",
            @"detail":@"将音频相关逻辑封装到播放器内",
            @"class":@"MR0x33ViewController",
        },
        @{
            @"title":@"0x34",
            @"detail":@"显示音视频播放进度",
            @"class":@"MR0x34ViewController",
        },
        @{
            @"title":@"0x35",
            @"detail":@"音视频同步",
            @"class":@"MR0x35ViewController",
        },
        @{
            @"title":@"0x36",
            @"detail":@"开始，结束，暂停，续播",
            @"class":@"MR0x36ViewController",
        },
        @{
            @"title":@"0x37",
            @"detail":@"(TODO)使用 FFmpeg 内置的硬件加速解码器",
            @"class":@"MR0x37ViewController",
        },
        @{
            @"title":@"0x38",
            @"detail":@"(TODO)统一软硬解渲染逻辑",
            @"class":@"MR0x3cViewController",
        },
        @{
            @"title":@"0x39",
            @"detail":@"(TODO)支持 Seek",
            @"class":@"MR0x37ViewController",
        },
        @{
            @"title":@"0x3a",
            @"detail":@"(TODO)支持从指定位置处播放",
            @"class":@"MR0x38ViewController",
        },
        @{
            @"title":@"五、趣味实验",
            @"isSection":@(YES)
        },
        @{
            @"title":@"Have Fun",
            @"detail":@"雪花屏，灰色色阶图，三个小球",
            @"class":@"MRHaveFunViewController",
        },
        @{
            @"title":@"六、实用工具",
            @"isSection":@(YES)
        },
        @{
            @"title":@"VTP",
            @"detail":@"高效视频抽帧器",
            @"url":@"https://github.com/debugly/MRVideoToPicture",
        },
        @{
            @"title":@"七、跨平台播放器",
            @"isSection":@(YES)
        },
        @{
            @"title":@"IJKPlayer",
            @"detail":@"移植到了 macOS 平台",
            @"url":@"https://github.com/debugly/ijkplayer",
        }
    ];
    
    [tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.dataArr.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    RootTableRowView *view = [tableView makeViewWithIdentifier:@"cell" owner:self];
    if (view == nil) {
        view = [[RootTableRowView alloc]init];
        view.identifier = @"cell";
    }
    NSDictionary *dic = self.dataArr[row];
    [view updateTitle:dic[@"title"]];
    [view updateDetail:dic[@"detail"]];
    BOOL isSection = [dic[@"isSection"] boolValue];
    [view updateArrow:isSection];
    
    BOOL isSeparactor = [dic[@"isSeparactor"] boolValue];
    if (isSeparactor) {
        view.sepStyle = KSeparactorStyleNone;
    } else {
        if (isSection) {
            view.sepStyle = KSeparactorStyleFull;
        } else {
            if (row + 1 <= [self.dataArr count] - 1) {
                if ([self tableView:tableView isGroupRow:row + 1]) {
                    view.sepStyle = KSeparactorStyleFull;
                } else {
                    view.sepStyle = KSeparactorStyleHeadPadding;
                }
            } else {
                view.sepStyle = KSeparactorStyleFull;
            }
        }
    }
    return view;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    if (row < [self.dataArr count]) {
        NSDictionary *dic = self.dataArr[row];
        return [dic[@"isSection"] boolValue];
    }
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if (row < [self.dataArr count]) {
        NSDictionary *dic = self.dataArr[row];
        BOOL isSeparactor = [dic[@"isSeparactor"] boolValue];
        if (isSeparactor) {
            return [dic[@"height"] floatValue];
        } else {
            BOOL isSection = [dic[@"isSection"] boolValue];
            return isSection ? 30 : 35;
        }
    } else {
        return 0.0;
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    NSDictionary *dic = self.dataArr[row];
    if ([dic[@"isSection"] boolValue]) {
        return NO;
    }
    Class clazz = NSClassFromString(dic[@"class"]);
    if (clazz) {
        NSViewController *vc = [[clazz alloc] init];
        vc.title = dic[@"detail"];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        NSString * url = dic[@"url"];
        if (url) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRow:row];
    });
    return YES;
}

@end
