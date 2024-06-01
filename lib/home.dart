import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'utils/index.dart';
import 'components/bottomPlay.dart';

class MusicApp extends StatefulWidget {
  const MusicApp({Key? key}) : super(key: key);

  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  dynamic _itemList = [];
  String listName = '';
  dynamic isEdit = false;

  @override
  void initState() {
    super.initState();
    getLocalList('playList').then((res) {
      setState(() => _itemList = res);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading : false,
        centerTitle: true,
        title: const Text('我的歌单'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Color(0xFFEEEFF2),
        padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 0.0),
        child: Column(
          children: [
            GestureDetector(
              child: Container(
                width: double.infinity,
                height: 50,
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.only(left: 10, right: 10),
                alignment: Alignment.centerLeft,
                color: Color(0xFFFFFFFF),
                child: Text('全部音乐', style: TextStyle(fontSize: 16),),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/allmusic');
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (ctx) {
                //       return AllMusic();
                //     }
                // ));
              },
            ),
            Expanded(
              child: Container(
                color: Color(0xFFFFFFFF),
                child: isEdit ? _reorderList() : _normalList(),
              ),
            ),
          ],
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

  Widget _reorderList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: const Text('拖动排序'),
            ),
            TextButton(
              child: const Text('完成'),
              onPressed: () {
                setState(() {
                  isEdit = !isEdit;
                  setLocalList('playList', _itemList);
                });
              },
            ),
          ],
        ),
        Expanded(child: ReorderableListView(
          children: [
            for (int index = 0; index < _itemList.length; index += 1)
              ListTile(
                key: Key('$index'),
                title: Text(_itemList[index]['name'], style: TextStyle(fontSize: 20),),
                trailing: Icon(Icons.reorder, size: 20, color: Colors.black54,),
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '歌单（${_itemList.length}个）',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.grey),
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('新建歌单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                        content: TextField(
                          onChanged: (String value) {
                            setState(() {
                              listName = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              setState(() {
                                listName = '';
                              });
                              Navigator.pop(context, 'Cancel');
                            },
                            child: const Text('取消', style: TextStyle(color: Colors.black87)),
                          ),
                          TextButton(
                            onPressed: () {
                              if (listName != '') {
                                setState(() {
                                  var item = { 'id': UniqueKey().toString(), 'name': listName, 'total': 0 };
                                  _itemList.insert(0, item);
                                  setLocalList('playList', _itemList);
                                  listName = '';
                                });
                                Navigator.pop(context, 'OK');
                              }
                            },
                            child: const Text('确定', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort_rounded, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      isEdit = !isEdit;
                    });
                  },
                )
              ],
            ),
          ],
        ),
        Expanded(
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
                            _itemList.removeAt(index);
                            setLocalList('playList', _itemList);
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
        title: Text(item['name'], style: const TextStyle(fontSize: 20),),
        trailing: Text(item['total'].toString(), style: const TextStyle(color: Color(0xFF999999), fontSize: 16),),
        onTap: () {
          Navigator.pushNamed(context, '/playlist', arguments: {'playListName': item['name']});
        },
      ),
    );
  }
}