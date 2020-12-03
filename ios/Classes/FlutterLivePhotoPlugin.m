#import "FlutterLivePhotoPlugin.h"
#if __has_include(<flutter_live_photo/flutter_live_photo-Swift.h>)
#import <flutter_live_photo/flutter_live_photo-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_live_photo-Swift.h"
#endif

@implementation FlutterLivePhotoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterLivePhotoPlugin registerWithRegistrar:registrar];
}
@end
