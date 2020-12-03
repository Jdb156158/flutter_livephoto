//
//  OcFlutterLivePhotoPlugin.m
//  flutter_live_photo
//
//  Created by db J on 2020/12/3.
//

#import "OcFlutterLivePhotoPlugin.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@implementation OcFlutterLivePhotoPlugin

+ (OcFlutterLivePhotoPlugin *)shared {
    static id _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });

    return _shared;
}

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"flutter_live_photo"
                  binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:[self shared] channel:channel];
    
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"generateFromLocalFile" isEqualToString:call.method]) {
        [self save2WithPhotoUrl:call.arguments[@"pngUrl"] videoUrl:call.arguments[@"fileUrl"] result:result];
    }else{
        result(FlutterMethodNotImplemented);
    }
}

-(void)save2WithPhotoUrl:(NSString *)photoURLstring videoUrl:(NSString *)videoURLstring result:(FlutterResult)result {
    
    NSLog(@"photoURLstring:%@",photoURLstring);
    NSLog(@"videoURLstring:%@",videoURLstring);
    
    NSURL *photoURL = [NSURL fileURLWithPath:photoURLstring];//@"...picture.jpg"
    NSURL *videoURL = [NSURL fileURLWithPath:videoURLstring];//@"...video.mov"
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto
                             fileURL:photoURL
                             options:nil];
        [request addResourceWithType:PHAssetResourceTypePairedVideo
                             fileURL:videoURL
                             options:nil];
        
    } completionHandler:^(BOOL success,
                          NSError * _Nullable error) {
        if (success) {
            NSLog(@"save success==保存成功");
            result(@"1");
        } else {
            NSLog(@"error==保存失败: %@",error);
            result(@"0");
        }
    }];
    
}
@end
