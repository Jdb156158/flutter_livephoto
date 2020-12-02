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
  String videoImage;
  String pngImage;

  @override
  void initState() {
    super.initState();
  }

  selectUrlVideo() async {
    // PickedFile file = await image.getVideo(source: ImageSource.gallery);

    String videoUrl =
        "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4";
    var result = await FlutterLivePhoto.generate(videoURL: videoUrl);
    // print(file.path);
    print("result = $result");
  }

  selectVideo() async {
    var image = ImagePicker();
    PickedFile file = await image.getVideo(source: ImageSource.gallery);

    videoImage = file.path;
    setState(() {

    });
  }

  selectImage() async {
    var image = ImagePicker();
    PickedFile file = await image.getImage(source: ImageSource.gallery);
    pngImage = file.path;
    setState(() {

    });
  }

  selectLocalVideo() async {
    var result = await FlutterLivePhoto.generateLocal(
        fileUrl: videoImage, pngUrl: pngImage);

    print("result $result");
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
            Text("data$videoImage"),

            Container(height: 50,),
            Text("data$pngImage"),

            RaisedButton(
              onPressed: selectVideo,
              child: Text("选视频"),
            ),
            RaisedButton(
              onPressed: selectImage,
              child: Text("选图片"),
            ),
            RaisedButton(
              onPressed: selectLocalVideo,
              child: Text("合成"),
            ),
          ],
        )),
      ),
    );
  }
}
