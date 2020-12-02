import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_live_photo/flutter_live_photo.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  final image = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  selectVideo() async {
    PickedFile file = await image.getVideo(source: ImageSource.gallery);

    print(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: RaisedButton(
            onPressed: selectVideo,
            child: Text("选择视频"),
          ),
        ),
      ),
    );
  }
}
