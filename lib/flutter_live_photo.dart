
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterLivePhoto {
  static const MethodChannel _channel =
      const MethodChannel('flutter_live_photo');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
