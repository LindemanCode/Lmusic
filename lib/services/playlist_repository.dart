import 'package:shared_preferences/shared_preferences.dart';
import '../utils/index.dart';

class PlaylistRepository {
  // Future<List<Map<String, String>>> fetchInitialPlaylist();
  // Future<Map<String, String>> fetchAnotherSong();
  getSongList({listName}) async {
    if (listName == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      listName = prefs.getString('listName');
    }
    var songList = await getLocalList(listName);
    return List.generate(songList.length, (index) => ({
      'id': songList[index]['id'],
      'title': songList[index]['alias'],
      'logo': songList[index]['logo'],
      'album': songList[index]['album'],
      'artist': songList[index]['artist'],
      'url': songList[index]['path'],
    }));
  }
}

// class DemoPlaylist extends PlaylistRepository {
//   @override
//   Future<List<Map<String, String>>> fetchInitialPlaylist(
//       {int length = 3}) async {
//     return List.generate(length, (index) => _nextSong());
//   }

//   @override
//   Future<Map<String, String>> fetchAnotherSong() async {
//     return _nextSong();
//   }

//   var _songIndex = 0;
//   static const _maxSongNumber = 16;

//   Map<String, String> _nextSong() {
//     _songIndex = (_songIndex % _maxSongNumber) + 1;
//     return {
//       'id': _songIndex.toString().padLeft(3, '0'),
//       'title': 'Song $_songIndex',
//       'album': 'SoundHelix',
//       'url':
//       'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-$_songIndex.mp3',
//     };
//   }
// }