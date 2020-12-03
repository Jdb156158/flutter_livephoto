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
- (void)save2WithPhotoUrl:(NSString *)photoURLstring videoUrl:(NSString *)videoURLstring{
    
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
        } else {
            NSLog(@"error==保存失败: %@",error);
        }
    }];
    
}
@end
