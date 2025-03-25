import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'utils/index.dart';
import 'components/songList.dart';
import 'home.dart';
import 'components/bottomPlay.dart';
import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class MPlayList extends StatefulWidget {
  final playListName;
  MPlayList({Key? key, @required this.playListName}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MPlayListState(playListName: playListName);
  }
}

class MPlayListState extends State<MPlayList> {
  final playListName;
  MPlayListState({Key? key, @required this.playListName});

  var uuid = Uuid();
  late Key _sListkey = Key(uuid.v1());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white,),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (cxt) {
                        return MusicApp();
                      }
                  ));
                }
            );
          },
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        title: const Text('歌单'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.download_sharp, color: Colors.white),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                final Directory? directory = await getApplicationDocumentsDirectory();
                if (result != null) {
                  dynamic tempArr = [];
                  for (var i = 0; i < result.files.length; i++) {
                    var path = result.files[i].path;
                    dynamic metadata = await MetadataRetriever.fromFile(File(path!));
                    var name = result.files[i].name;
                    var extension = result.files[i].extension;
                    var alias = metadata.trackName ?? name.split('.$extension')[0];
                    var id = uuid.v1();
                    var logoPath = '';
                    if (metadata.albumArt != null && directory != null) {
                      // 保存图片到应用文件目录
                      logoPath = '${directory.path}/$alias$id';
                      await File(logoPath).writeAsBytes(metadata.albumArt);
                    }
                    tempArr.insert(0, {
                      'id': id,
                      'name': name,
                      'alias': alias,
                      'logo': logoPath,
                      'parentId': [],
                      'path': path,
                      'artist': metadata.trackArtistNames == null ? '-' : metadata.trackArtistNames[0],
                      'album': metadata.albumName ?? '',
                      'isChecked': false,
                    });
                  }
                  tempArr.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
                  dynamic allSongList = await getLocalList('allMusic');
                  allSongList.insertAll(0, tempArr);
                  setLocalList('allMusic', allSongList);
                  for (int sidx = tempArr.length - 1; sidx > -1; sidx--) {
                    await updateSong(tempArr[sidx], 'add', 'playList$playListName');
                  }
                  setState(() {
                    _sListkey = Key(uuid.v1());
                  });
                }
              }
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Color(0xFFF4F4F4),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(top: 40, bottom: 40, left: 20, right: 20),
                child: Text(playListName, style: const TextStyle(color: Colors.black, fontSize: 30),),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))
                  ),
                  child: SongList(key: _sListkey, listName: 'playList$playListName'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        padding: EdgeInsets.zero,
        color: Colors.white,
        shadowColor: Colors.black,
        child: BottomPlay(),
      ),
    );
  }
}