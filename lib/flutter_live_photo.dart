
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterLivePhoto {
  static const MethodChannel _channel =
      const MethodChannel('flutter_live_photo');


  static Future<bool> generate({
    String videoURL,
  }) async {
    final bool status = await _channel.invokeMethod(
      'generateFromURL',
      <String, dynamic>{
        "videoURL": videoURL,
      },
    );
    return status;
  }


  static Future<bool> generateLocal({
    String fileUrl,
    String pngUrl
  }) async {
    final bool status = await _channel.invokeMethod(
      'generateFromLocalFile',
      <String, dynamic>{
        "fileUrl": fileUrl,
        "pngUrl":pngUrl
      },
    );
    return status;
  }


  static Future<bool> openSettings() async {
    final bool status = await _channel.invokeMethod('openSettings');
    return status;
  }
}
