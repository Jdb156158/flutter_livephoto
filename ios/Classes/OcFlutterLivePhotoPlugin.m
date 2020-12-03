//
//  OcFlutterLivePhotoPlugin.m
//  flutter_live_photo
//
//  Created by db J on 2020/12/3.
//

#import "OcFlutterLivePhotoPlugin.h"
#import <Photos/Photos.h>
#import <CoreMedia/CMMetadata.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface OcFlutterLivePhotoPlugin()
@property (nonatomic) AVAssetExportSession *session;
@property (nonatomic) AVURLAsset *asset;
@property (nonatomic) AVAssetReader *reader;
@property (nonatomic) AVAssetWriter *writer;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) dispatch_group_t group;
@end
@implementation OcFlutterLivePhotoPlugin

+ (OcFlutterLivePhotoPlugin *)shared {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });

    return _shared;
}

-(void)save2WithPhotoUrl:(NSString *)photoURLstring videoUrl:(NSString *)videoURLstring {
    
    NSLog(@"photoURLstring:%@",photoURLstring);
    NSLog(@"videoURLstring:%@",videoURLstring);
    
    NSURL *photoURL = [NSURL fileURLWithPath:photoURLstring];//@"...picture.jpg"
    NSURL *videoURL = [NSURL fileURLWithPath:videoURLstring];//@"...video.mov"
    
    BOOL available = [PHAssetCreationRequest supportsAssetResourceTypes:@[@(PHAssetResourceTypePhoto), @(PHAssetResourceTypePairedVideo)]];
    if (!available) {
        NSLog(@"设备不支持LivePhoto.");
        if (self.Result) {
            self.Result(NO);
        }
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            NSLog(@"照片库被拒绝访问.");
            if (self.Result) {
                self.Result(NO);
            }
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //保存中
        });
        NSString *identifier = [NSUUID UUID].UUIDString;
        [self useAssetWriter:photoURL video:videoURL identifier:identifier complete:^(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error) {
            
            NSURL *photo = [NSURL fileURLWithPath:photoFile];
            NSURL *video = [NSURL fileURLWithPath:videoFile];
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photo options:nil];
                [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:video options:nil];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"Saved.");
                    [self deleteFlutterSaveIosFile:photoURLstring andVideoString:videoURLstring];
                    if (self.Result) {
                        self.Result(YES);
                    }
                }else {
                    NSLog(@"Save error: %@", error);
                    if (self.Result) {
                        self.Result(NO);
                    }
                }
            }];
        }];
    }];
    
}

- (void)useAssetWriter:(NSURL *)photoURL video:(NSURL *)videoURL identifier:(NSString *)identifier complete:(void (^)(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error))complete {
    // Photo
    NSString *photoName = [photoURL lastPathComponent];
    NSString *photoFile = [self filePathFromDoc:photoName];
    [self addMetadataToPhoto:photoURL outputFile:photoFile identifier:identifier];
    
    // Video
    NSString *videoName = [videoURL lastPathComponent];
    NSString *videoFile = [self filePathFromDoc:videoName];
    [self addMetadataToVideo:videoURL outputFile:videoFile identifier:identifier];
    
    if (!self.group) return;
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        [self finishWritingTracksWithPhoto:photoFile video:videoFile complete:complete];
    });
}

- (void)addMetadataToPhoto:(NSURL *)photoURL outputFile:(NSString *)outputFile identifier:(NSString *)identifier {
    NSMutableData *data = [NSData dataWithContentsOfURL:photoURL].mutableCopy;
    UIImage *image = [UIImage imageWithData:data];
    CGImageRef imageRef = image.CGImage;
    NSDictionary *imageMetadata = @{(NSString *)kCGImagePropertyMakerAppleDictionary : @{@"17" : identifier}};
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeJPEG, 1, nil);
    CGImageDestinationAddImage(dest, imageRef, (CFDictionaryRef)imageMetadata);
    CGImageDestinationFinalize(dest);
    [data writeToFile:outputFile atomically:YES];
}

- (void)addMetadataToVideo:(NSURL *)videoURL outputFile:(NSString *)outputFile identifier:(NSString *)identifier {
    NSError *error = nil;
    
    // Reader
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (error) {
        NSLog(@"Init reader error: %@", error);
        return;
    }
    NSMutableArray<AVMetadataItem *> *metadata = asset.metadata.mutableCopy;
    AVMetadataItem *item = [self createContentIdentifierMetadataItem:identifier];
    [metadata addObject:item];
    
    // Writer
    NSURL *videoFileURL = [NSURL fileURLWithPath:outputFile];
    [self deleteFile:outputFile];
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:videoFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        NSLog(@"Init writer error: %@", error);
        return;
    }
    [writer setMetadata:metadata];
    
    // Tracks
    NSArray<AVAssetTrack *> *tracks = [asset tracks];
    for (AVAssetTrack *track in tracks) {
        NSDictionary *readerOutputSettings = nil;
        NSDictionary *writerOuputSettings = nil;
        if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
            readerOutputSettings = @{AVFormatIDKey : @(kAudioFormatLinearPCM)};
            writerOuputSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                    AVSampleRateKey : @(44100),
                                    AVNumberOfChannelsKey : @(2),
                                    AVEncoderBitRateKey : @(128000)};
        }
        AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerOutputSettings];
        AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:track.mediaType outputSettings:writerOuputSettings];
        if ([reader canAddOutput:output] && [writer canAddInput:input]) {
            [reader addOutput:output];
            [writer addInput:input];
        }
    }
    
    // Metadata track
    AVAssetWriterInput *input = [self createStillImageTimeAssetWriterInput];
    AVAssetWriterInputMetadataAdaptor *adaptor = [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:input];
    if ([writer canAddInput:input]) {
        [writer addInput:input];
    }
    
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    
    // Write metadata track's metadata
    AVMetadataItem *timedItem = [self createStillImageTimeMetadataItem];
    CMTimeRange timedRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1, 100));
    AVTimedMetadataGroup *timedMetadataGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[timedItem] timeRange:timedRange];
    [adaptor appendTimedMetadataGroup:timedMetadataGroup];
    
    // Write other tracks
    self.reader = reader;
    self.writer = writer;
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.group = dispatch_group_create();
    for (NSInteger i = 0; i < reader.outputs.count; ++i) {
        dispatch_group_enter(self.group);
        [self writeTrack:i];
    }
}

- (void)writeTrack:(NSInteger)trackIndex {
    AVAssetReaderOutput *output = self.reader.outputs[trackIndex];
    AVAssetWriterInput *input = self.writer.inputs[trackIndex];
    
    [input requestMediaDataWhenReadyOnQueue:self.queue usingBlock:^{
        while (input.readyForMoreMediaData) {
            AVAssetReaderStatus status = self.reader.status;
            CMSampleBufferRef buffer = NULL;
            if ((status == AVAssetReaderStatusReading) &&
                (buffer = [output copyNextSampleBuffer])) {
                BOOL success = [input appendSampleBuffer:buffer];
                CFRelease(buffer);
                if (!success) {
                    NSLog(@"Track %d. Failed to append buffer.", (int)trackIndex);
                    [input markAsFinished];
                    dispatch_group_leave(self.group);
                    return;
                }
            } else {
                if (status == AVAssetReaderStatusReading) {
                    NSLog(@"Track %d complete.", (int)trackIndex);
                } else if (status == AVAssetReaderStatusCompleted) {
                    NSLog(@"Reader completed.");
                } else if (status == AVAssetReaderStatusCancelled) {
                    NSLog(@"Reader cancelled.");
                } else if (status == AVAssetReaderStatusFailed) {
                    NSLog(@"Reader failed.");
                }
                [input markAsFinished];
                dispatch_group_leave(self.group);
                return;
            }
        }
    }];
}

- (void)finishWritingTracksWithPhoto:(NSString *)photoFile video:(NSString *)videoFile complete:(void (^)(BOOL success, NSString *photoFile, NSString *videoFile, NSError *error))complete {
    [self.reader cancelReading];
    [self.writer finishWritingWithCompletionHandler:^{
        if (complete) complete(YES, photoFile, videoFile, nil);
    }];
}

- (AVMetadataItem *)createContentIdentifierMetadataItem:(NSString *)identifier {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    item.key = AVMetadataQuickTimeMetadataKeyContentIdentifier;
    item.value = identifier;
    return item;
}

- (AVAssetWriterInput *)createStillImageTimeAssetWriterInput {
    NSArray *spec = @[@{(NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier : @"mdta/com.apple.quicktime.still-image-time",
                        (NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType : (NSString *)kCMMetadataBaseDataType_SInt8 }];
    CMFormatDescriptionRef desc = NULL;
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)spec, &desc);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:desc];
    return input;
}

- (AVMetadataItem *)createStillImageTimeMetadataItem {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.keySpace = AVMetadataKeySpaceQuickTimeMetadata;
    item.key = @"com.apple.quicktime.still-image-time";
    item.value = @(-1);
    item.dataType = (NSString *)kCMMetadataBaseDataType_SInt8;
    return item;
}

- (NSString *)filePathFromDoc:(NSString *)filename {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:filename];
    return filePath;
}

- (void)deleteFile:(NSString *)file {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:file]) {
        [fm removeItemAtPath:file error:nil];
    }
}

//如果成功则删除flutter那边保存在沙盒Library/Caches下的所需的合成livephoto文件
- (void)deleteFlutterSaveIosFile:(NSString *)photoURLstring andVideoString:(NSString *)videoURLstring{
    
    // 实例化NSFileManager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    bool removepng = [fileManager removeItemAtPath:photoURLstring error:nil];
    bool removevideo = [fileManager removeItemAtPath:videoURLstring error:nil];
    NSLog(@"===清除废旧不用的资源情况:【removepng：%d===removepng:%d】",removepng,removevideo);

}
@end
