import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'page_manager.dart';
import 'services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/index.dart';
import 'dart:async';
import 'dart:io';

class PlayMusic extends StatefulWidget {
  final listName;
  final songIdx;
  const PlayMusic({Key? key, this.listName, this.songIdx}) : super(key: key);

  @override
  _PlayMusicPageState createState() => _PlayMusicPageState(listName: listName, songIdx: songIdx);
}

class _PlayMusicPageState extends State<PlayMusic>  with TickerProviderStateMixin {
  _PlayMusicPageState({Key? key, this.listName, this.songIdx});
  final listName;
  final songIdx;
  dynamic songList;
  dynamic playList = [];
  dynamic timeCloseList = [
    { 'time': 15, 'active': false },
    { 'time': 30, 'active': false },
    { 'time': 45, 'active': false },
    { 'time': 60, 'active': false },
  ];
  bool collectVisible = false;
  int countTime = 0;
  dynamic closeTimer;
  bool closeVisible = false;
  bool isClose = false;
  String closeTimeStr = '00:00';


  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 18),
    vsync: this,
  )..repeat();
  late final Animation<double> _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

  setListName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('listName', listName);
  }

  @override
  void initState() {
    super.initState();
    if (songIdx != null) {
      setListName();
      getIt<PageManager>().init(listName, songIdx);
    }
    getLocalList('playList').then((res) {
      setState(() => playList = res);
    });
    getLocalList(listName).then((res) {
      setState(() => songList = res);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${listName == 'allMusic' ? '全部音乐' : listName.substring(8)}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            iconSize: 20,
            iconColor: Colors.white,
            color: const Color.fromRGBO(0, 0, 0, 0.5),
            itemBuilder:(BuildContext context) => [
              PopupMenuItem(
                value: 1,
                child: const ListTile(
                  leading: Icon(Icons.add_box_outlined),
                  title: Text('收藏到歌单'),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                ) ,
                onTap: () {
                  setState(() => collectVisible = true);
                },
              ),
              PopupMenuItem(
                value: 2,
                child: const ListTile(
                  leading: Icon(Icons.timer_outlined),
                  title: Text('定时关闭'),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                ) ,
                onTap: () async {
                  setState(() => closeVisible = true);
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    disc(),
                    CurrentSongTitle(songList: songList),
                    AudioProgressBar(),
                    AudioControlButtons(),
                  ],
                ),
              ),
              if (closeVisible || collectVisible) BlackBG(),
              if (collectVisible) CollectPanel(),
              if (closeVisible) ClosePanel(),
            ],
          ),
      ),
    );
  }

  Widget disc() {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<String>(
      valueListenable: pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        dynamic item;
        if (songList != null) {
          songList.forEach((song) {
            if (song['alias'] == title) item = song;
          });
        }
        Widget noneImg() {
          return Container(
            width: 190,
            height: 190,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(95),
              image: const DecorationImage(
                image: NetworkImage('https://gd-hbimg.huaban.com/1dc2d5610bc0ebc55a0dbc189c7d39925133761ffaad-W2TUpN_fw1200'),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        Widget showImg() {
          return Container(
            width: 210,
            height: 210,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(125),
              image: DecorationImage(
                image: FileImage(File(item['logo'])),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return ValueListenableBuilder<ButtonState>(
          valueListenable: pageManager.playButtonNotifier,
          builder: (_, value, __) {
            if (value == ButtonState.playing) {
              _controller.repeat();
            } else {
              _controller.stop();
            }
            return RotationTransition(
              turns: _animation,
              child: Container(
                width: 310,
                height: 310,
                margin: const EdgeInsets.only(left: 20, right: 20, top: 80, bottom: 80),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  border: Border.all(width: 50),
                  borderRadius: BorderRadius.circular(155),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 7.0,
                    ),
                  ],
                ),
                child: songList == null || item == null || item['logo'] == null || item['logo'] == '' ? noneImg() : showImg(),
              ),
            );
          });
      }
    );
  }

  Widget BlackBG() {
    return GestureDetector(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(0x7F000000),
      ),
      onTap: () {
        setState(() {
          closeVisible = false;
          collectVisible = false;
        });
      },
    );
  }

  Widget CollectPanel() {
    dynamic item;
    dynamic songName = getIt<PageManager>().currentSongTitleNotifier.value;
    songList.forEach((song) {
      if (song['alias'] == songName) item = song;
    });
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child:Container(
    width: double.infinity,
    height: 500,
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
              child: Text('${item['alias']}   收藏到歌单：', style: const TextStyle(fontSize: 16)),
            ),
            IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey,),
                onPressed: () {
                  setState(() => collectVisible = false);
                },
            )
          ],
        ),
        Container(
          width: double.infinity,
          height: 450,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1))),
          ),
          child: ListView.builder(
            itemCount: playList.length,
            itemBuilder: (BuildContext context, int pIdx) {
              if (pIdx < playList.length) {
                var pItem = playList[pIdx];
                return ListTile(
                  title: Text(pItem['name'], style: const TextStyle(fontSize: 20)),
                  contentPadding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 0),
                  onTap: () {
                    updateSong(item, 'add', 'playList${pItem['name']}').then((isHas) {
                      if (isHas) {
                        showToast('歌曲已存在 ${pItem['name']} 歌单');
                      } else {
                        showToast('成功收藏到 ${pItem['name']} 歌单');
                      }
                      setState(() => collectVisible = false);
                    });
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    ),
  )
    );
  }

  Widget ClosePanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                  child: const Text('定时关闭', style: TextStyle(fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey,),
                  onPressed: () {
                    setState(() => closeVisible = false);
                  },
                )
              ],
            ),
            Container(
              width: double.infinity,
              height: 100,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1))),
              ),
              child: ListTile(
                title: Text('$closeTimeStr 后关闭'),
                trailing: isClose ? Switch(
                  value: isClose,
                  activeColor: Colors.blue,
                  onChanged: (bool value) {
                    setState(() {
                      isClose = value;
                      if (!value) {
                        cancelTimer();
                        countTime = 0;
                        closeTimeStr = constructTime(countTime);
                      }
                    });
                  },
                ) : Text('-'),
              ) ,

            ),
            Container(
              width: 320,
              height: 60,
              alignment: Alignment.center,
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: timeCloseList.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = timeCloseList[index];
                    return Container(
                      padding: EdgeInsets.all(5),
                      child: ElevatedButton(
                        child: Text('${item['time']}', style: TextStyle(fontSize: 18, color: item['active'] ? Colors.white : Colors.black ),),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(item['active'] ? Colors.blue : Colors.white),
                          shape: MaterialStateProperty.all(CircleBorder(
                              side: BorderSide(width: 40.0, style: BorderStyle.none)
                          )
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            timeCloseList.forEach((timer) => timer['active'] = false);
                            item['active'] = true;
                            countTime = item['time'] * 60;
                            closeTimeStr = constructTime(countTime);
                            isClose = true;
                            startTimer();
                          });
                        },
                      ),
                    );
                  }
              ),
            ),
          ],
        ),
      )
    );
  }

  void startTimer() {
    //设置 1 秒回调一次
    const period = const Duration(seconds: 1);
    closeTimer = Timer.periodic(period, (timer) {
      //更新界面
      setState(() {
        //秒数减一，因为一秒回调一次
        countTime--;
        closeTimeStr = constructTime(countTime);
      });
      if (countTime == 0) {
        //倒计时秒数为0，取消定时器
        cancelTimer(isStop: true);
      }
    });
  }

  void cancelTimer({isStop}) {
    if (closeTimer != null) {
      closeTimer.cancel();
      closeTimer = null;
      timeCloseList.forEach((timer) => timer['active'] = false);
      setState(() => isClose = false);
      if (isStop) {
        final pageManager = getIt<PageManager>();
        pageManager.pause();
      }
    }
  }
}

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key, this.songList}) : super(key: key);
  final songList;

  setCurSong(songName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentSong', songName);
  }

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<String>(
      valueListenable: pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        setCurSong(title);
        dynamic item;
        if (songList != null) {
          songList.forEach((song) {
            if (song['alias'] == title) item = song;
          });
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, height: 0.9)),
              const SizedBox(height: 12),
              if (item != null) Text('${item['artist']}-${item['album']}', style: const TextStyle(fontSize: 13, height: 0.9, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: pageManager.progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progressBarColor: Colors.blue,
          thumbColor: Colors.blue,
          progress: value.current,
          buffered: value.buffered,
          baseBarColor: Colors.black.withOpacity(0.24),
          bufferedBarColor: Colors.black.withOpacity(0),
          total: value.total,
          onSeek: pageManager.seek,
        );
      },
    );
  }
}

class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          RepeatButton(),
          PreviousSongButton(),
          PlayButton(),
          NextSongButton(),
          ListButton(),
        ],
      ),
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    var msg = '';
    return ValueListenableBuilder<RepeatState>(
      valueListenable: pageManager.repeatButtonNotifier,
      builder: (context, value, child) {
        Icon icon;
        switch (value) {
          case RepeatState.shuffle:
            icon = const Icon(Icons.shuffle_rounded);
            msg = '单曲循环';
            break;
          case RepeatState.repeatSong:
            icon = const Icon(Icons.repeat_one);
            msg = '列表循环';
            break;
          case RepeatState.repeatPlaylist:
            icon = const Icon(Icons.repeat);
            msg = '随机播放';
            break;
        }
        return IconButton(
          icon: icon,
          onPressed: () {
            showToast(msg);
            pageManager.repeat();
          },
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<bool>(
      valueListenable: pageManager.isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 40.0,
          onPressed: pageManager.previous,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 56.0,
              height: 56.0,
              child: const CircularProgressIndicator(color: Colors.blue,),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              iconSize: 56.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause_rounded),
              iconSize: 56.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return IconButton(
      icon: const Icon(Icons.skip_next),
      iconSize: 40.0,
      onPressed: pageManager.next,
    );
  }
}

class ListButton extends StatelessWidget {
  const ListButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<List<String>>(
        valueListenable: pageManager.playlistNotifier,
        builder: (context, playlistTitles, _) {
          return ValueListenableBuilder<String>(
            valueListenable: pageManager.currentSongTitleNotifier,
            builder: (_, title, __) {
              return MenuAnchor(
                style: MenuStyle(maximumSize: MaterialStateProperty.all(Size.fromHeight(500.0))),
                builder:
                    (BuildContext context, MenuController controller, Widget? child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.list),
                  );
                },
                menuChildren: List<MenuItemButton>.generate(
                  playlistTitles.length,
                  (int index) => MenuItemButton(
                    onPressed: () => pageManager.skipToSong(index),
                    child: Text(
                      playlistTitles[index],
                      style: TextStyle(color: title == playlistTitles[index] ? Colors.blue : Colors.black)
                    ),
                  ),
                ),
              );
            },
          );
        },
    );
  }
}