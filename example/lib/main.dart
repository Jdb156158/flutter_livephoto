import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_live_photo/flutter_live_photo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  Directory _libraryDirectory;

  @override
  void initState() {
    super.initState();


    initDirect();
  }

  initDirect() async {
    _libraryDirectory = await getTemporaryDirectory();
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
    var split = file.path.split(".");
    var seed = DateTime.now().millisecondsSinceEpoch;
    videoImage = _libraryDirectory.path + "/${seed}.${split.last}";
    print("videoUrl$videoImage");
    new File(file.path).copySync(videoImage);
    setState(() {

    });
  }

  selectImage() async {
    var image = ImagePicker();
    PickedFile file = await image.getImage(source: ImageSource.gallery);

    var split = file.path.split(".");
    var seed = DateTime.now().millisecondsSinceEpoch;
    pngImage = _libraryDirectory.path + "/$seed.${split.last}";
    print("videoUrl$pngImage");
    new File(file.path).copySync(pngImage);
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
                Text("$videoImage"),

                Container(height: 50,),
                Text("$pngImage"),

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
