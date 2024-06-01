import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../utils/index.dart';
import 'dart:io';

class SongList extends StatefulWidget {
  final listName;
  const SongList({Key? key, this.listName}) : super(key: key);

  @override
  _SongListPageState createState() => _SongListPageState(listName: listName);
}

class _SongListPageState extends State<SongList> {
  _SongListPageState({Key? key, this.listName});
  final listName;
  dynamic _itemList = [];
  dynamic playList = [];
  dynamic isEdit = false;
  dynamic isAllChecked = false;
  dynamic curList;
  dynamic curSong;

  getCurName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      curList = prefs.getString('listName');
      curSong = prefs.getString('currentSong');
    });
  }

  @override
  void initState() {
    super.initState();
    getLocalList(listName).then((res) {
      setState(() => _itemList = res);
    });
    getLocalList('playList').then((res) {
      setState(() => playList = res);
    });
    getCurName();
  }

  @override
  Widget build(BuildContext context) {
    return isEdit ? _reorderList() : _normalList();
  }

  Widget _reorderList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 200,
              child: CheckboxListTile(
                title: const Text('全选'),
                controlAffinity: ListTileControlAffinity.leading,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                side: const BorderSide(color: Colors.blue, width: 1.0),
                activeColor: Colors.blue,
                value:  isAllChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isAllChecked = value;
                    _itemList.forEach((song) => song['isChecked'] = value);
                  });
                },
              ),
            ),
            Row(
              children: [
                TextButton(
                  child: const Text('收藏'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
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
                                    child: const Text('收藏到歌单：', style: TextStyle(fontSize: 16)),
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.grey,),
                                      onPressed: () => Navigator.pop(context)
                                  )
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                height: 450,
                                padding: const EdgeInsets.only(top: 10),
                                decoration: const BoxDecoration(
                                    border: Border(top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1))),
                                ),
                                child: ListView.builder(
                                  itemCount: playList.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    if (index < playList.length) {
                                      var pItem = playList[index];
                                      return ListTile(
                                        title: Text(pItem['name'], style: const TextStyle(fontSize: 20)),
                                        contentPadding: const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 0),
                                        onTap: () async {
                                          dynamic hasCount = 0;
                                          for (int sidx = _itemList.length - 1; sidx > -1; sidx--) {
                                            if (_itemList[sidx]['isChecked']) {
                                              dynamic isHas = await updateSong(_itemList[sidx], 'add', 'playList${pItem['name']}');
                                              if (isHas) hasCount = hasCount + 1;
                                            }
                                          }
                                          if (hasCount > 0) {
                                            showToast('有 $hasCount 首已存在 ${pItem['name']} 歌单');
                                          } else {
                                            showToast('成功收藏到 ${pItem['name']} 歌单');
                                          }
                                          getLocalList(listName).then((res) {
                                            setState(() {
                                              if (res != null) _itemList = res;
                                              _itemList.forEach((song) => song['isChecked'] = false);
                                              Navigator.pop(context);
                                            });
                                          });
                                        },
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              // ElevatedButton(
                              //   child: const Text('Close BottomSheet'),
                              //   onPressed: () => Navigator.pop(context),
                              // ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                TextButton(
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    dynamic remainArr = [];
                    for (int sidx = 0; sidx < _itemList.length; sidx++) {
                      if (_itemList[sidx]['isChecked']) {
                        await updateSong(_itemList[sidx], 'del', listName);
                      } else {
                        remainArr.add(_itemList[sidx]);
                      }
                    }
                    setState(() => _itemList = remainArr);
                  },
                ),
                TextButton(
                  child: const Text('完成', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    setState(() {
                      isEdit = !isEdit;
                      isAllChecked = false;
                      setLocalList(listName, _itemList);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        Expanded(child: ReorderableListView(
          children: [
            for (int index = 0; index < _itemList.length; index += 1)
              CheckboxListTile(
                key: Key('$index'),
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3.0),
                      child: _itemList[index]['logo'] == '' || _itemList[index]['logo'] == null ? _noneImg(_itemList[index], size: 30.0) : _showImg(_itemList[index], size: 30.0),
                    ),
                    const SizedBox(width: 5),
                    Text(_itemList[index]['alias'], style: TextStyle(
                      fontSize: 17,
                      height: 0.9,
                      color: curList == listName && _itemList[index]['alias'] == curSong ? Colors.blue : Colors.black,
                    ))
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: const Icon(Icons.reorder, size: 18, color: Colors.black54,),
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                side: const BorderSide(color: Colors.blue, width: 1.0),
                activeColor: Colors.blue,
                value: _itemList[index]['isChecked'],
                onChanged: (bool? value) {
                  setState(() {
                    _itemList[index]['isChecked'] = value;
                    dynamic tempCheck = true;
                    _itemList.forEach((song) {
                      if (!song['isChecked']) tempCheck = false;
                    });
                    isAllChecked = tempCheck;
                  });
                },
              ),
          ],
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              dynamic item = _itemList.removeAt(oldIndex);
              _itemList.insert(newIndex, item);
            });
          },
        ))
      ],
    );
  }

  Widget _normalList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              child: Container(
                width: 300,
                height: 50,
                padding: const EdgeInsets.only(left: 10, right: 10),
                alignment: Alignment.centerLeft,
                color: const Color(0xFFFFFFFF),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.only(right: 6, left: 1),
                        child: const Icon(Icons.play_circle_filled_rounded, color: Colors.blue)
                    ),
                    const Text('播放全部', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('（${_itemList.length}）'),
                  ],
                ),
              ),
              onTap: () {
                int idx = Random().nextInt(_itemList.length);
                Navigator.pushNamed(context, '/play', arguments: {'playListName': listName, 'songIdx': idx});
              },
            ),
            IconButton(
              icon: const Icon(Icons.sort_rounded, color: Colors.grey),
              onPressed: () {
                setState(() {
                  isEdit = !isEdit;
                  _itemList.forEach((song) => song['isChecked'] = false);
                });
              },
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFFFFF),
            child: ListView.separated(
              scrollDirection: Axis.vertical,
              itemCount: _itemList.length,
              itemBuilder: (BuildContext context, int index) {
                if (index < _itemList.length) {
                  var item = _itemList[index];
                  return _buildListItem(index, item);
                }
                return const SizedBox.shrink();
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 1);
              },
              // 添加下面这句 内容未充满的时候也可以滚动。
              physics: const AlwaysScrollableScrollPhysics(),
              // 添加下面这句 是为了GridView的高度自适应, 否则GridView需要包裹在固定宽高的容器中。
              //shrinkWrap: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(index, item) {
    return Slidable(
      // Specify a key if the Slidable is dismissible.
        key: Key(item['id']),
        endActionPane: ActionPane(
          dragDismissible: false,
          extentRatio: 0.25,
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              backgroundColor: const Color(0xFFFE4A49),
              foregroundColor: Colors.white,
              label: '删除',
              onPressed: (x) {
                showDialog (
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('提示'),
                        content: const Text('确认删除？'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('取消', style: TextStyle(color: Colors.black87)),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                var item = _itemList[index];
                                _itemList.removeAt(index);
                                updateSong(item, 'del', listName);
                              });
                              Navigator.pop(context, 'OK');
                            },
                            child: const Text('确定', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      );
                    }
                );
              },
            ),
          ],
        ),
        // The child of the Slidable is what the user sees when the component is not dragged.
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 20),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: item['logo'] == '' || item['logo'] == null ? _noneImg(item) : _showImg(item),
          ),
          // leading: Text((index + 1).toString(), style: const TextStyle(color: Colors.grey),),
          minLeadingWidth: 5,
          title: Text(
            item['alias'],
            style: TextStyle(
              fontSize: 17,
              height: 0.9,
              color: curList == listName && item['alias'] == curSong ? Colors.blue : Colors.black,
            ),
          ),
          subtitle: Text(
            '${item['artist']}${item['album'] == '' ? '' : '-' + item['album']}',
            style: const TextStyle(fontSize: 13, height: 0.9, color: Colors.grey)
          ),
          onTap: () {
            Navigator.pushNamed(context, '/play', arguments: {'playListName': listName, 'songIdx': index});
          },
          trailing: PopupMenuButton(
            iconSize: 20,
            iconColor: Colors.grey,
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
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
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
                                    onPressed: () => Navigator.pop(context)
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
                                          getLocalList(listName).then((res) {
                                            setState(() {
                                              if (res != null) _itemList = res;
                                              _itemList.forEach((song) => song['isChecked'] = false);
                                              Navigator.pop(context);
                                            });
                                          });
                                        });
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            // ElevatedButton(
                            //   child: const Text('Close BottomSheet'),
                            //   onPressed: () => Navigator.pop(context),
                            // ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              PopupMenuItem(
                value: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.5)))
                      ),
                      child: const Text('已收藏歌单', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(
                        width: 200,
                        height: 60,
                        child: ListView.builder(
                          itemCount: item['parentId'].length,
                          itemBuilder: (BuildContext context, int pIdx) {
                            if (pIdx < item['parentId'].length) {
                              var lName = item['parentId'][pIdx].substring(8);
                              return Text(lName, style: const TextStyle(color: Colors.white,) );
                            }
                            return const SizedBox.shrink();
                          },
                        )
                    ),
                  ],
                ),
              ),
            ],
            //     ),
          ),
        )
    );
  }

  Widget _noneImg(item, { size = 44.0 }) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0x99000000),
      width: size,
      height: size,
      child: Text(item['alias'].substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 20),),
    );
  }

  Widget _showImg(item, { size = 44.0 }) {
    _getImageFile(String path) async {
      return File(path);
    }
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<File>(
        future: _getImageFile(item['logo']),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // 图片文件已经获取成功
            return Image.file(snapshot.data!);
          } else if (snapshot.hasError) {
            // 加载图片出错
            return Text(item['alias'].substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 20),);
          }
          // 正在加载图片
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}






