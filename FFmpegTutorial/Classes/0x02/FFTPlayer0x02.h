//
//  FFTPlayer0x02.h
//  FFmpegTutorial
//
//  Created by qianlongxu on 2020/5/14.
//

#import <Foundation/Foundation.h>
#import "FFTPlayerHeader.h"

NS_ASSUME_NONNULL_BEGIN


@class FFTPlayer0x02;

@protocol FFTPlayer0x02Delegate <NSObject>

- (void)player:(FFTPlayer0x02 *)player receiveMediaStream:(NSString *)info;
- (void)player:(FFTPlayer0x02 *)player occureError:(NSError *)error;
// call frequently
- (void)player:(FFTPlayer0x02 *)player whenReadPacket:(int)audioPacketCount videoPacketCount:(int)videoPacketCount;
// call frequently
- (void)player:(FFTPlayer0x02 *)player whenDecodeFrame:(int)audioFrame videoFrameCount:(int)videoFrameCount;

@end

@interface FFTPlayer0x02 : NSObject

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
@property (nonatomic, weak) id<FFTPlayer0x02Delegate> delegate;
//@property (nonatomic, copy) void(^onReadPkt)(FFTPlayer0x02 *player,int a,int v);
//@property (nonatomic, copy) void(^onDecoderFrame)(FFTPlayer0x02 *player,int a,int v);
//@property (nonatomic, copy) void(^onError)(FFTPlayer0x02 *player,NSError *);

///准备
- (void)prepareToPlay;
///读包
- (void)play;
///停止读包
- (void)asyncStop;

@end

NS_ASSUME_NONNULL_END
