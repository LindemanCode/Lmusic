import 'package:flutter/foundation.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';
import 'package:audio_service/audio_service.dart';
import 'services/playlist_repository.dart';
import 'services/service_locator.dart';
import 'dart:io';
import 'dart:core';

class PageManager {
  // Listeners: Updates going to the UI
  final currentSongTitleNotifier = ValueNotifier<String>('');
  final curSongLogoNotifier = ValueNotifier<String>('');
  final playlistNotifier = ValueNotifier<List<String>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  final _audioHandler = getIt<AudioHandler>();
  dynamic _songIdx;
  dynamic isFirst = true;


  // Events: Calls coming from the UI
  void init(listName, songIdx) async {
    _songIdx = songIdx;
    isFirst = true;
    await _loadPlaylist(listName);
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }

  Future<void> _loadPlaylist(listName) async {
    if (isFirst) {
      for (int index = _audioHandler.queue.value.length - 1; index > -1; index -= 1) {
        _audioHandler.removeQueueItemAt(index);
      }
    }
    final songRepository = getIt<PlaylistRepository>();
    final playlist = await songRepository.getSongList(listName: listName);
    print('歌曲列表-$playlist');
    List<MediaItem> mediaItems = [];
    playlist.forEach((song) => mediaItems.add(MediaItem(
      id: song['id'] ?? '',
      album: song['album'] ?? '',
      title: song['title'] ?? '',
      artist: song['artist'] ?? '',
      extras: {'url': song['url'], 'logo': song['logo']},
      artUri: song['logo'] != null && song['logo'] != '' ? Uri.file(song['logo']) : Uri.parse('https://gd-hbimg.huaban.com/1dc2d5610bc0ebc55a0dbc189c7d39925133761ffaad-W2TUpN_fw1200'),
    )));
     _audioHandler.addQueueItems(mediaItems.toList());
  }

  void _listenToChangesInPlaylist() {
    _audioHandler.queue.listen((playlist) async {
      if (playlist.isEmpty) {
        playlistNotifier.value = [];
        currentSongTitleNotifier.value = '';
      } else {
        if (isFirst) {
          isFirst = false;
          final songRepository = getIt<PlaylistRepository>();
          final _playlist = await songRepository.getSongList();
          List<String> newList = [];
          _playlist.forEach((song) => newList.add(song['title']));
          newList = newList.toList();
          playlistNotifier.value = newList;
          Future.delayed(Duration(milliseconds: 200), () {
            skipToSong(_songIdx);
          });
        }
      }
      _updateSkipButtons();
    });
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioHandler.seek(Duration.zero);
        _audioHandler.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _audioHandler.playbackState.listen((playbackState) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: playbackState.bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenToTotalDuration() {
    _audioHandler.mediaItem.listen((mediaItem) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });
  }

  void _listenToChangesInSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      currentSongTitleNotifier.value = mediaItem?.title ?? '';
      curSongLogoNotifier.value = mediaItem?.extras?['logo'] ?? '';
      _updateSkipButtons();
    });
  }

  void _updateSkipButtons() {
    final mediaItem = _audioHandler.mediaItem.value;
    final playlist = _audioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();

  void seek(Duration position) => _audioHandler.seek(position);

  void previous() async {
    _audioHandler.skipToPrevious();
    _audioHandler.play();
  }
  void next() async { 
    _audioHandler.skipToNext();
    _audioHandler.play();
  }
  void skipToSong(index) async {
    _audioHandler.skipToQueueItem(index);
    _audioHandler.play();
  }

  void repeat() {
    repeatButtonNotifier.nextState();
    final repeatMode = repeatButtonNotifier.value;
    switch (repeatMode) {
      case RepeatState.shuffle:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
        break;
      case RepeatState.repeatSong:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
        break;
      case RepeatState.repeatPlaylist:
        _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
        break;
    }
  }

  void shuffle() {
    final enable = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enable;
    if (enable) {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  void dispose() {
    _audioHandler.customAction('dispose');
  }

  void stop() {
    _audioHandler.stop();
  }
}