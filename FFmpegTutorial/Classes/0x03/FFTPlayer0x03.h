//
//  FFTPlayer0x10.h
//  FFmpegTutorial
//
//  Created by qianlongxu on 2022/7/5.
//

#import <Foundation/Foundation.h>
#import "FFTPlayerHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct AVFrame AVFrame;
//videoOpened info's key
typedef NSString * const kFFTPlayer0x10InfoKey;

//视频宽；单位像素
FOUNDATION_EXPORT kFFTPlayer0x10InfoKey kFFTPlayer0x10Width;
//视频高；单位像素
FOUNDATION_EXPORT kFFTPlayer0x10InfoKey kFFTPlayer0x10Height;

@class FFTPlayer0x03;

@protocol FFTPlayer0x03Delegate <NSObject>

- (void)player:(FFTPlayer0x03 *)player receiveMediaStream:(NSString *)info pixWidth:(CGFloat)w pixHeight:(CGFloat)h;
- (void)player:(FFTPlayer0x03 *)player occureError:(NSError *)error;
// call frequently
- (void)player:(FFTPlayer0x03 *)player whenReadPacket:(int)audioPacketCount videoPacketCount:(int)videoPacketCount;
// call frequently
- (void)player:(FFTPlayer0x03 *)player whenDecodeFrameType:(int)frameType frameCount:(int)count frame:(AVFrame *)frame;

@end

@interface FFTPlayer0x03 : NSObject

///播放地址
@property (nonatomic, copy) NSString *contentPath;
///code is FFPlayerErrorCode enum.
@property (nonatomic, strong, nullable) NSError *error;
///记录读到的视频包总数
@property (atomic, assign, readonly) int videoPktCount;
///记录读到的音频包总数
@property (atomic, assign, readonly) int audioPktCount;
///记录解码后的视频桢总数
@property (atomic, assign, readonly) int videoFrameCount;
///记录解码后的音频桢总数
@property (atomic, assign, readonly) int audioFrameCount;
///期望的像素格式
@property (nonatomic, assign) MRPixelFormatMask supportedPixelFormats;
@property (nonatomic, weak) id<FFTPlayer0x03Delegate> delegate;
//@property (nonatomic, copy) void(^onVideoOpened)(FFTPlayer0x03 *player,NSDictionary *info);
//@property (nonatomic, copy) void(^onReadPkt)(FFTPlayer0x03 *player,int a,int v);
////type: 1->video;2->audio;
//@property (nonatomic, copy) void(^onDecoderFrame)(FFTPlayer0x03 *player,int type,int serial,AVFrame *frame);
//@property (nonatomic, copy) void(^onError)(FFTPlayer0x03 *player,NSError *);

///准备
- (void)prepareToPlay;
///读包
- (void)play;
///停止读包
- (void)asyncStop;

@end

NS_ASSUME_NONNULL_END
