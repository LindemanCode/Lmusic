import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

setLocalList(key, originList) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final List<String> itemList = [];
  for (int i = 0; i < originList.length; i++) itemList.add(jsonEncode(originList[i]));
  prefs.setStringList(key, itemList);
}

getLocalList(key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  dynamic dataList = prefs.getStringList(key);
  dynamic  itemList = [];
  if (dataList != null) {
    for (int i = 0; i < dataList.length; i++) itemList.add(jsonDecode(dataList[i]));
  }
  return itemList;
}

updateSong(song, action, playListName, {ctx}) async {
  dynamic playList = await getLocalList('playList');
  var showListName = playListName.substring(8);

  // 更新所有收藏歌单
  song['parentId'].forEach((name) async {
    if (name != playListName) {
      dynamic songList = await getLocalList('playList${name}');
      songList.forEach((item) {
        if (item['id'] == song['id']) {
          if (action == 'add') item['parentId'].insert(0, playListName);
          if (action == 'del') item['parentId'].remove(playListName);
        }
      });
      setLocalList('playList${name}', songList);
    }
  });

  // 更新目标歌单
  dynamic songList = [];
  dynamic resList = await getLocalList(playListName);
  if (resList != null) songList = resList;
  var isHas = false;
  songList.forEach((item) {
    if (item['id'] == song['id']) isHas = true;
  });
  if (action == 'add') {
    if (isHas) {

    } else {
      song['parentId'].insert(0, playListName);
      songList.insert(0, song);
      playList.forEach((list) {
        if (list['name'] == showListName) list['total'] = list['total'] + 1;
      });
    }
  }
  if (action == 'del') {
    song['parentId'].remove(playListName);
    int delIdx = songList.indexWhere((s) => s['id'] == song['id']);
    if (delIdx > -1) songList.removeAt(delIdx);
    playList.forEach((list) {
      if (list['name'] == showListName) list['total'] = list['total'] - 1;
      if (list['total'] < 0) list['total'] = 0;
    });
  }
  setLocalList(playListName, songList);
  setLocalList('playList', playList);

  // 更新全部音乐
  dynamic allMusic = await getLocalList('allMusic');
  allMusic.forEach((item) {
    if (item['id'] == song['id']) {
      if (!isHas && action == 'add') item['parentId'].insert(0, playListName);
      if (action == 'del') item['parentId'].remove(playListName);
    }
  });
  setLocalList('allMusic', allMusic);

  return isHas;
}

void showToast(
    String text, {
      gravity = ToastGravity.CENTER,
      toastLength = Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: text,
    gravity: gravity,
    toastLength: toastLength,
    backgroundColor: Color.fromRGBO(0, 0, 0, 0.5), // 灰色背景
    fontSize: 16.0,
  );
}

//时间格式化，根据总秒数转换为对应的 hh:mm:ss 格式
String constructTime(int seconds) {
  int hour = seconds ~/ 3600;
  int minute = seconds % 3600 ~/ 60;
  int second = seconds % 60;
  if (seconds > 3600) {
    return formatTime(hour) + ":" + formatTime(minute) + ":" + formatTime(second);
  } else {
    return formatTime(minute) + ":" + formatTime(second);
  }
}

//数字格式化，将 0~9 的时间转换为 00~09
String formatTime(int timeNum) {
  return timeNum < 10 ? "0" + timeNum.toString() : timeNum.toString();
}
