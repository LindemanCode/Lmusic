import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'utils/index.dart';

class PlayState with ChangeNotifier {
  var isPlay = true;
  dynamic song = { 'alias': '--' };
  var songIdx = 0;
  dynamic songList = [];
  var listModel = 'all';
  dynamic songDuration;
  double playingTime = 0.0;
  double totalTime = 0.0;
  final _player = AudioPlayer();

  playInit(listName, songId) async {
    getLocalList(listName).then((res) async {
      songList = res;
      for (int i = 0; i < songList.length; i++) {
        if (songList[i]['id'] == songId) {
          song = songList[i];
          songIdx = i;
        }
      }
      List<AudioSource> pathList = [];
      songList.forEach((item) => pathList.add(AudioSource.file(item['path'])));
      final playlist = ConcatenatingAudioSource(
        // Start loading next item just before reaching it
        useLazyPreparation: true,
        // Customise the shuffle algorithm
        shuffleOrder: DefaultShuffleOrder(),
        // Specify the playlist items
        children: pathList,
      );
      await _player.setAudioSource(playlist, initialIndex: songIdx, initialPosition: Duration.zero);
      _player.setLoopMode(LoopMode.all);
      _player.currentIndexStream.listen((index) {
        song = songList[index];
        notifyListeners();
      });
      play();
      _player.durationStream.listen((duration) {
        if (duration != null) {
          playingTime = 0.0;
          songDuration = duration;
          totalTime = songDuration.inSeconds.toDouble();
        }
      });
      _player.positionStream.listen((duration) {
        playingTime = duration.inSeconds.toDouble();
        notifyListeners();
      });
    });
  }

  play() async {
    isPlay = true;
    _player.play();
    notifyListeners();
  }

  pause() async {
    isPlay = false;
    _player.pause();
    notifyListeners();
  }

  toPrevious() async {
    play();
    _player.seekToPrevious();
    notifyListeners();
  }

  toNext() async {
    play();
    _player.seekToNext();
    notifyListeners();
  }

  setLoopModel() {
    if (listModel == 'all') {
      listModel = 'one';
      _player.setLoopMode(LoopMode.one);
    } else if (listModel == 'one') {
      listModel = 'shuffle';
      _player.setLoopMode(LoopMode.all);
      _player.setShuffleModeEnabled(true);
    } else if (listModel == 'shuffle') {
      listModel = 'all';
      _player.setShuffleModeEnabled(false);
    }
    notifyListeners();
  }

  setTime(time) {
    playingTime = time;
    _player.seek(Duration(seconds: time.round()));
    notifyListeners();
  }
}

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, // mix in default queue callback implementations
        SeekHandler { // mix in default seek callback implementations

  final _playState = PlayState();
  // The most common callbacks:
  Future<void> play() async {
    // All 'play' requests from all origins route to here. Implement this
    // callback to start playing audio appropriate to your app. e.g. music.
    _playState.play();
  }
  Future<void> pause() async {_playState.pause();}
  Future<void> skipToPrevious() async {_playState.toPrevious();}
  Future<void> skipToNext() async {_playState.toNext();}
  Future<void> seek(Duration position) async {_playState.setTime(position);}
  Future<void> skipToQueueItem(int i) async {}
}