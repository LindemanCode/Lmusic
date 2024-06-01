import 'package:flutter/material.dart';
import 'components/songList.dart';
import 'home.dart';
import 'components/bottomPlay.dart';

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
                  child: SongList(listName: 'playList$playListName'),
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