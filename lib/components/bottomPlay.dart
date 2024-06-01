import 'package:flutter/material.dart';
import '../notifiers/play_button_notifier.dart';
import '../page_manager.dart';
import '../services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../play.dart';
import 'dart:io';

class BottomPlay extends StatefulWidget {
  const BottomPlay({Key? key}) : super(key: key);

  @override
  _BottomPlayPageState createState() => _BottomPlayPageState();
}

class _BottomPlayPageState extends State<BottomPlay>  with TickerProviderStateMixin {
  dynamic curList;
  _BottomPlayPageState({Key? key,});

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 18),
    vsync: this,
  )..repeat();
  late final Animation<double> _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

  getCurName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      curList = prefs.getString('listName');
    });
  }

  @override
  void initState() {
    super.initState();
    getCurName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 15, right: 15),
      leading: disc(),
      title: CurrentSongTitle(),
      trailing: PlayButton(),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (cxt) {
              return PlayMusic(listName: curList,);
            }
        ));
      },
    );
  }

  Widget disc() {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        if (value == ButtonState.playing) {
          _controller.repeat();
        } else {
          _controller.stop();
        }
        return ValueListenableBuilder<String>(
          valueListenable: pageManager.curSongLogoNotifier,
          builder: (_, logo, __) {
            Widget noneImg() {
              return Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: NetworkImage('https://gd-hbimg.huaban.com/1dc2d5610bc0ebc55a0dbc189c7d39925133761ffaad-W2TUpN_fw1200'),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            Widget showImg() {
              return Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: FileImage(File(logo)),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return RotationTransition(
              turns: _animation,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  border: Border.all(width: 6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: logo == null || logo == '' ? noneImg() : showImg(),
              ),
            );
          },
        );
      });
    
  }
}

class CurrentSongTitle extends StatelessWidget {
  const CurrentSongTitle({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<String>(
      valueListenable: pageManager.currentSongTitleNotifier,
      builder: (_, title, __) {
        return title == null ? _textCon('--') : _textCon(title);
      },
    );
  }

  Widget _textCon(title) {
    return Container(
      width: double.infinity,
      child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 19, height: 1.2)
      ),
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
              width: 30.0,
              height: 30.0,
              child: const CircularProgressIndicator(color: Colors.blue,),
            );
          case ButtonState.paused:
            return IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded),
              iconSize: 30.0,
              onPressed: pageManager.play,
            );
          case ButtonState.playing:
            return IconButton(
              icon: const Icon(Icons.pause_circle_outline_rounded),
              iconSize: 30.0,
              onPressed: pageManager.pause,
            );
        }
      },
    );
  }
}