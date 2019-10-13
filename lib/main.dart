import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_image_picker/src/asset.dart';

var _status=true;
var _uploadStatus = false;
var _isImageSelected=false;
void main() {
  runApp(MaterialApp(
    title: 'Address',
    home: AddImages(),
  ));
}

class AddImages extends StatelessWidget{
   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add House Images',
      theme: ThemeData(brightness: Brightness.light),
      home: MultiImage(),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Upload', icon: Icons.cloud_upload),
  const Choice(title: 'Post House Deal', icon: Icons.check)
];

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({Key key, this.choice}) : super(key: key);

  final Choice choice;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.display1;
    return Card(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(choice.icon, size: 128.0, color: textStyle.color),
            Text(choice.title, style: textStyle),
          ],
        ),
      ),
    );
  }
}

class MultiImage extends StatefulWidget {
  @override
  _MultiImageState createState() => new _MultiImageState();
}

class _MultiImageState extends State<MultiImage> {
    List<Asset> images = List<Asset>();
    List <String> imagePaths = List<String>();
   String _error = 'No Error Dectected';

   @override
   void initState() {
     super.initState();
   }

  String filePath;
  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  var imageDataPath = { };
  int i=0,len;
  Future<Null> _addImages(var pic) async {
      var t = await pic.filePath;
      File file=new File(t);
      filePath = '${DateTime.now()}.png';
      StorageReference ref = FirebaseStorage(storageBucket: 'gs://farfromhome-2019.appspot.com/').ref().child(filePath); 
      StorageUploadTask task = ref.putFile(file);
      StorageTaskSnapshot storageTaskSnapshot = await task.onComplete;
      String url = await storageTaskSnapshot.ref.getDownloadURL();
      
      //print("\nUploaded: "+url);
      //Download URL's 
      imageDataPath[i] = url;
      setState((){
        i++;
      });
      if(len==i+1){
        setState(() {
          _status=!_status;
          _uploadStatus=!_uploadStatus;
        });
      }
      
  }

  //Uploading images
  Future<Null> _uploadImages(){
    setState(() {
      len = images.length;
      _uploadStatus=!_uploadStatus;
    });
    images.forEach((pic) {
      _addImages(pic);
    });
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#1972d2",
          actionBarTitle: "Select Images",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );

      for (var r in resultList) {
        var t = await r.filePath;
        //print(t);
      }
      if(resultList.isNotEmpty){
        setState(() {
          _isImageSelected = true;
        });
      }else{
        setState(() {
          _isImageSelected = false;
        });
      }
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: AppBar(
           title: Text("Add House Images"),
           backgroundColor: Colors.blue[700],
           actions: _isImageSelected ? <Widget>[
              // action button
              _status ? IconButton(
                icon: Icon(choices[0].icon),
                onPressed: () {
                  _uploadImages();
                },
              )
              : IconButton(
                icon: Icon(choices[1].icon),
                onPressed: () {
                  print('Saved');
                },
              ),
           ] : null,
         ),
        body: _uploadStatus ? Center(child:new CircularProgressIndicator()) : new Column( 
          children: <Widget>[
            Expanded(
              child: buildGridView(),
            ),
          ],
        ),
        floatingActionButton: _status ? FloatingActionButton(
        onPressed: () {
          loadAssets();
        },
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.blue[700],
      ): null,
      ),
    );
  }
}
