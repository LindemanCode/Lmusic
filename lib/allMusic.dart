import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'utils/index.dart';
import 'components/songList.dart';
import 'home.dart';
import 'components/bottomPlay.dart';
import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';

class AllMusic extends StatefulWidget {
  const AllMusic({Key? key}) : super(key: key);

  @override
  _AllMusicPageState createState() => _AllMusicPageState();
}

class _AllMusicPageState extends State<AllMusic> {
  late Key _sListkey = UniqueKey();

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
        title: const Text('全部音乐'),
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
                    var id = UniqueKey().toString();
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
                  setState(() {
                    _sListkey = UniqueKey();
                  });
                }
              }
          ),
        ],
      ),
      body: SafeArea(
        child: SongList(key: _sListkey, listName: 'allMusic'),
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