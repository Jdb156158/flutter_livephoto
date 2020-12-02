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

  selectUrlVideo() async {
    // PickedFile file = await image.getVideo(source: ImageSource.gallery);

    String videoUrl = "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4";
    var result = await FlutterLivePhoto.generate(videoURL: videoUrl);
    // print(file.path);
    print("result = $result");
  }

  selectLocalVideo() async{
    PickedFile file = await image.getVideo(source: ImageSource.gallery);

    var imageresul = await image.getImage(source: ImageSource.gallery);

    var result = await FlutterLivePhoto.generateLocal(fileUrl: file.path,pngUrl: imageresul.path);

    // print(file.path);
    print("result = $result");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(

            children: [
              RaisedButton(
                onPressed: selectUrlVideo,
                child: Text("选择video视频"),
              ),

              RaisedButton(
                onPressed: selectLocalVideo,
                child: Text("选择本地视频"),
              ),
            ],
          )
        ),
      ),
    );
  }
}
