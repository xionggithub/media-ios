//
//  VideoFileSource.m
//  media
//
//  Created by 飞拍科技 on 2019/6/10.
//  Copyright © 2019 飞拍科技. All rights reserved.
//

#import "VideoFileSource.h"


@implementation VideoFileSource

- (id)initWithFileUrl:(NSURL *)fileUrl
{
    if (self = [super init]) {
        self.fURL = fileUrl;
        self.isPull = NO;
    }
    
    return self;
}

- (void)setVideoWidth:(int)vwidth height:(int)vheight
{
    self.width = vwidth;
    self.height = vheight;
}

- (void)beginPullVideo
{
    if (self.workThread == nil) {
        self.workThread = [[NSThread alloc] initWithTarget:self selector:@selector(pullRunloop) object:nil];
        [self.workThread start];
    }
}

- (void)pullRunloop
{
    NSString *path = self.fURL.path;
    if (path.length == 0) {
        NSLog(@"路径不能为空");
        return;
    }
    
    // 以二进制方式读取文件
    FILE *yuvFile = fopen([path UTF8String], "rb");
    if (yuvFile == NULL) {
        NSLog(@"打开YUV 文件失败");
        return;
    }
    if (self.width <= 0 || self.height <= 0) {
        NSLog(@"");
    }
    
    
    while (![NSThread currentThread].isCancelled) {
        
        // 读取YUV420 planner格式的视频数据，其一帧视频数据的大小为 宽*高*3/2;
        VideoFrame frame = {0};
        frame.luma = (uint8_t*)malloc(self.width * self.height);
        frame.chromaB = (uint8_t*)malloc(self.width * self.height/4);
        frame.chromaR = (uint8_t*)malloc(self.width * self.height/4);
        frame.width = self.width;
        frame.height = self.height;
        
        fread(frame.luma, 1, self.width * self.height, yuvFile);
        fread(frame.chromaB, 1, self.width * self.height/4, yuvFile);
        fread(frame.chromaR, 1, self.width * self.height/4, yuvFile);
        
        if ([self.delegate respondsToSelector:@selector(pushYUVFrame:)]) {
            [self.delegate pushYUVFrame:&frame];
        }
        
        // 写入速度比渲染速度快一些
        usleep(usec_per_fps * 0.8);
    }
}

- (void)stop
{
    if (self.workThread) {
        [self.workThread cancel];
        self.workThread = nil;
    }
}
@end
