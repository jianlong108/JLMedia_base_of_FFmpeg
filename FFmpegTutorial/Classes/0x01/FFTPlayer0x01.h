//
//  FFTPlayer0x01.h
//  FFmpegTutorial
//
//  Created by qianlongxu on 2020/4/26.
//

#import <Foundation/Foundation.h>
#import "FFTPlayerHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class FFTPlayer0x01;

@protocol FFTPlayer0x01Delegate <NSObject>

- (void)player:(FFTPlayer0x01 *)player receiveMediaStream:(NSString *)info;
- (void)player:(FFTPlayer0x01 *)player occureError:(NSError *)error;
// call frequently
- (void)player:(FFTPlayer0x01 *)player whenReadPacket:(int)audioPacketCount videoPacketCount:(int)videoPacketCount;

@end

@interface FFTPlayer0x01 : NSObject

///播放地址
@property (nonatomic, copy) NSString *contentPath;
///code is FFPlayerErrorCode enum.
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, weak) id<FFTPlayer0x01Delegate> delegate;
///准备
- (void)prepareToPlay;
///读包
//- (void)openStream:(void(^)(NSError * _Nullable error,NSString * _Nullable info))completion;
///停止读包
- (void)asyncStop;

@end

NS_ASSUME_NONNULL_END
