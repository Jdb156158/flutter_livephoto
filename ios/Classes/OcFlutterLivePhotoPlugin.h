//
//  OcFlutterLivePhotoPlugin.h
//  flutter_live_photo
//
//  Created by db J on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

@interface OcFlutterLivePhotoPlugin : NSObject
@property (nonatomic,copy) void (^Result)(bool res);
+ (OcFlutterLivePhotoPlugin *)shared;
-(void)save2WithPhotoUrl:(NSString *)photoURLstring videoUrl:(NSString *)videoURLstring;
@end

NS_ASSUME_NONNULL_END
