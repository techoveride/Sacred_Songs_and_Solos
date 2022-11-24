import 'dart:convert';
import 'dart:io';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/model/hymn.dart';
import 'package:path_provider/path_provider.dart';

GlobalKey<_HymnListingState> hymnGKey = GlobalKey();

class HymnListing extends StatefulWidget {
  final ValueChanged<Hymns>? hymnSelectedCallback;
  final Hymns? hymnSelected;
  HymnListing(
      {Key? key, @required this.hymnSelectedCallback, this.hymnSelected})
      : super(key: key);

  @override
  _HymnListingState createState() => _HymnListingState();
}

class _HymnListingState extends State<HymnListing> {
  late File jsonFile;
  late Directory dir;
  String fileName = "HymnLyricsEnglish.json";
  bool fileExists = false;

  late List<Hymns> _hymnList;
  late int hymnSize;
  var hymn;

  final ScrollController _scrollControl = ScrollController();

  static const double _itemExtent = 58.0;

  Future<List<Hymns>> getHymn() async {
    jsonFile = await _localFile;
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      hymn = json.decode(jsonFile.readAsStringSync());
      setState(() {
        _hymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
        hymnSize = _hymnList.length;
      });
    }
    return _hymnList;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/HymnLyricsEnglish.json');
  }

  // Future<File> _writeData(String message) async {
  //   final file = await _localFile;
  //   return file.writeAsString('$message');
  // }

  final GlobalKey<_HymnListingState> hymnListingKey =
      GlobalKey<_HymnListingState>();

  onSearchedItem(String value) {
//    print(value);
    setState(() {
      _hymnList =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i))).where((item) {
        String search =
            "${indexOptimiser(item.id)} ${item.title.trim().toLowerCase()} ${item.lyric.toLowerCase()}";
        return search.contains(value.toLowerCase());
      }).toList();
      hymnSize = _hymnList.length;
    });
//    print(hymnSize);
  }

  sortByTitle() {
    Comparator<Hymns> titleComparator = (a, b) => (a.title).compareTo(b.title);

    setState(() {
      _hymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
      _hymnList.sort(titleComparator);
    });
  }

  sortByNumber() {
    setState(() {
      _hymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
//      _hymnList.sort((a, b) => (a.id).compareTo(b.id));
    });
  }

  loadHymn() async {
    setState(() {
      _hymnList = globals.defaultHymn;
    });
  }

  @override
  void initState() {
    loadHymn();
    getHymn();

    super.initState();
  }

  onSearchExit(String value) {
    setState(() {
      _hymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
      hymnSize = _hymnList.length;
    });
  }

  String titleCase(String title) {
    if (title.isEmpty) {
      throw ArgumentError("String:$title");
      // return title;
    }
    return title.split(' ').map((word) {
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return hymnList();
  }

//  Widget hymnList() {
//    if (hymnSize != null)
//      return ListView(
//        children: _hymnList.map((hymn) {
//          return Card(
//            elevation: 4.5,
//            margin: EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
//            child: ListTile(
//              title: Text(hymn.title),
//              selected: widget.hymnSelected == hymn,
//              onTap: () => widget.hymnSelectedCallback(hymn),
//            ),
//          );
//        }).toList(),
//      );
//    else {
//      return Container();
//    }
//  }
//
//  Widget hymnList() {
//    return Padding(
//        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
//        child: FutureBuilder(
//          future: getHymn(),
//          builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
//            if (snapshot.hasData) {
//              return ListView.builder(
//                  itemCount: hymnSize,
//                  itemBuilder: (_, index) {
//                    return Card(
//                      elevation: 4.5,
//                      margin:
//                          EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
//                      child: ListTile(
//                        title: Text(
//                          "${_hymnList[index].title}",
//                        ),
//                        selected: widget.hymnSelected == _hymnList[index],
//                        onTap: () =>
//                            widget.hymnSelectedCallback(_hymnList[index]),
//                      ),
//                    );
//                  });
//            } else {
//              return Center(
//                  child: CircularProgressIndicator(
//                strokeWidth: 6.0,
//                value: 4.0,
//              ));
//  ListView(
//                children: <Widget>[
//                  Card(
//                    elevation: 4.5,
//                    margin: EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
//                    child: ListTile(
//                      title: Text("Hymn Not found"),
//                      subtitle: Text("Please enter Hymn Number or Title!"),
//                    ),
//                  )
//                ],
//              );
//            }
//          },
//        ));
//  }
  Widget hymnList() {
    return Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: DraggableScrollbar.arrows(
              alwaysVisibleScrollThumb: true,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.only(right: 4.0),
              labelTextBuilder: (double offset) => Text(
                  "${(offset ~/ _itemExtent) + 1}",
                  style: const TextStyle(color: Colors.white)),
              controller: _scrollControl,
              child: ListView.builder(
                controller: _scrollControl,
                itemCount: _hymnList.length,
                itemExtent: _itemExtent,
                itemBuilder: (_, index) {
                  return Card(
                    elevation: 4.5,
                    margin: const EdgeInsets.only(
                        bottom: 3.0, right: 4.0, left: 4.0),
                    child: ListTile(
                        leading: Text(
                          indexOptimiser(_hymnList[index].id),
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18.0,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                        title: Text(
                          titleCase(_hymnList[index].title.trim()),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                        selected: widget.hymnSelected == _hymnList[index],
                        onTap: () async {
                          widget.hymnSelectedCallback!(
                            _hymnList[index],
                          );
                          if (globals.isPlaying) await globals.player.stop();
                          globals.load(_hymnList[index].id.toString());
                        }),
                  );
                },
              ),
            ),
          ),
          // const AnchoredAdaptiveAd(),
        ]);
  }
}

String indexOptimiser(int id) {
  String output;
  if (id.toString().length == 1) {
    output = "000$id";
    return output;
  } else if (id.toString().length == 2) {
    output = "00$id";
    return output;
  } else if (id.toString().length == 3) {
    output = "0$id";
    return output;
  } else {
    return id.toString();
  }
}
