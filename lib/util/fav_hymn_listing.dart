import 'dart:convert';
import 'dart:io';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:hymn_book/ads/anchored_adaptive_ad.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/model/hymn.dart';
import 'package:path_provider/path_provider.dart';

GlobalKey<_FavHymnListingState> favHymnGKey = GlobalKey();

class FavHymnListing extends StatefulWidget {
  final ValueChanged<Hymns>? hymnSelectedCallback;
  final Hymns? hymnSelected;
  FavHymnListing({
    Key? key,
    @required this.hymnSelectedCallback,
    this.hymnSelected,
  }) : super(key: key);

  @override
  _FavHymnListingState createState() => _FavHymnListingState();
}

class _FavHymnListingState extends State<FavHymnListing> {
  late List<Hymns> _favHymnList;
  late int hymnSize;

  final GlobalKey<_FavHymnListingState> hymnListingKey =
      GlobalKey<_FavHymnListingState>();

  final ScrollController _scrollControl = ScrollController();

  static const double _itemExtent = 58.0;

  late List hymn;

  IconData favIcon = Icons.favorite;

  // final IconData _off = Icons.flash_off;
  final IconData _on = Icons.flash_on;

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

  onSearchedItem(String value) {
    // print(value);
    setState(() {
      _favHymnList = listHymns.where((item) {
        String search =
            "${indexOptimiser(item.id)} ${item.title.trim().toLowerCase()} ${item.lyric.toLowerCase()}";
        return search.contains(value.toLowerCase()) && item.favorite == 1;
      }).toList();
      hymnSize = _favHymnList.length;
    });
  }

  sortByTitle() {
    Comparator<Hymns> titleComparator = (a, b) => (a.title).compareTo(b.title);

    setState(() {
      _favHymnList =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i))).where((val) {
        return val.favorite == 1;
      }).toList();
      _favHymnList.sort(titleComparator);
    });
  }

  sortByNumber() {
    setState(() {
      _favHymnList =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i))).where((val) {
        return val.favorite == 1;
      }).toList();
//      _hymnList.sort((a, b) => (a.id).compareTo(b.id));
    });
  }

/*  refresh() {
    setState(() {
      _favHymnList =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i))).where((val) {
        return val.favorite == 1;
      }).toList();
      hymnSize = _favHymnList.length;
    });
  }*/

  late File jsonFile;
  late Directory dir;
  String fileName = "HymnLyricsEnglish.json";
  bool fileExists = false;

  Future<List<Hymns>> getHymn() async {
    jsonFile = await _localFile;
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      hymn = json.decode(jsonFile.readAsStringSync());
      setState(() {
        _favHymnList =
            List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i))).where((item) {
          return item.favorite == 1;
        }).toList();
        hymnSize = _favHymnList.length;
      });
    }
//    favInit();
    return _favHymnList;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/HymnLyricsEnglish.json');
  }

  loadFav() async {
    setState(() => _favHymnList = globals.defaultHymn.where((val) {
          return val.favorite == 1;
        }).toList());
  }

  @override
  void initState() {
    loadFav();
    getHymn();
    super.initState();
  }

  onSearchExit(String value) {
    setState(() {
      _favHymnList = listHymns.where((item) {
        return item.favorite == 1;
      }).toList();
      hymnSize = _favHymnList.length;
    });
  }

  String titleCase(String title) {
    // if (title == null) throw ArgumentError("String:$title");
    if (title.isEmpty) {
      throw ArgumentError("String:$title");
    }
    return title.split(' ').map((word) {
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return hymnFavList();
  }

  Widget hymnFavList() {
    return Stack(alignment: AlignmentDirectional.bottomCenter, children: <
        Widget>[
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
          child: _favHymnList.isNotEmpty
              ? ListView.builder(
                  controller: _scrollControl,
                  itemCount: _favHymnList.length,
                  itemBuilder: (_, index) {
                    return Card(
                      elevation: 4.5,
                      margin: const EdgeInsets.only(
                          bottom: 3.0, right: 4.0, left: 4.0),
                      child: ListTile(
                          leading: Text(
                            indexOptimiser(_favHymnList[index].id),
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18.0,
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                          trailing: IconButton(
                              icon: Icon(favIcon),
                              onPressed: () {
                                int row = _favHymnList[index].id - 1;
                                updateFavorite(row);
                                if (MediaQuery.of(context).orientation ==
                                    Orientation.portrait) {
                                  snackBuilder(index);
                                } else {
                                  tabSnackBuilder(context, index);
                                }
                              }),
                          title: Text(
                            titleCase(_favHymnList[index].title.trim()),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                          selected: widget.hymnSelected == _favHymnList[index],
                          onTap: () => widget.hymnSelectedCallback!(
                                _favHymnList[index],
                              )),
                    );
                  },
                )
              : ListView(
                  children: const <Widget>[
                    Card(
                      elevation: 4.5,
                      margin:
                          EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
                      child: ListTile(
                        title: Text("Favorite Hymn Not found"),
                        subtitle: Text(
                            "Add a Hymn by clicking on the favorite icon!"),
                      ),
                    )
                  ],
                ),
        ),
      ),
      OrientationBuilder(builder: (context, orientation) {
        if (MediaQuery.of(context).orientation == Orientation.portrait) {
          return const AnchoredAdaptiveAd();
        } else {
          return Container();
        }
      })
    ]);
  }

  /* Widget hymnFavList() {
    if (hymnSize != null)
      return ListView(
        children: _favHymnList.map((hymn) {
          return Card(
            elevation: 4.5,
            margin: EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
            child: ListTile(
              title: Text(hymn.title),
              selected: widget.hymnSelected == hymn,
              onTap: () => widget.hymnSelectedCallback(hymn),
            ),
          );
        }).toList(),
      );
    else {
      return Container();
    }
  }*/

//  Widget hymnList() {
//    return ListView(
//      children: listHymns.map((hymn) {
//        return Container(
//          child: ListTile(
//            title: Text(hymn.setup),
//            selected: widget.hymnSelected == hymn,
//            onTap: () => widget.hymnSelectedCallback(hymn),
//          ),
//          decoration: BoxDecoration(
//              shape: BoxShape.rectangle,
//              color: Colors.blue[50],
//              borderRadius: BorderRadius.circular(5.0)),
//        );
//      }).toList(),
//    );
//  }
  /* Widget hymnFavList() {
    return Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        child: FutureBuilder(
          future: getHymn(),
          builder: (BuildContext buildContext, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: hymnSize,
                  itemBuilder: (_, index) {
                    return Card(
                      elevation: 4.5,
                      margin:
                          EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
                      child: ListTile(
                        title: Text(
                          "${_favHymnList[index].title}",
                        ),
                        selected: widget.hymnSelected == _favHymnList[index],
                        onTap: () =>
                            widget.hymnSelectedCallback(_favHymnList[index]),
                      ),
                    );
                  });
            } else {
              return ListView(
                children: <Widget>[
                  Card(
                    elevation: 4.5,
                    margin: EdgeInsets.only(bottom: 3.0, right: 4.0, left: 4.0),
                    child: ListTile(
                      title: Text("Hymn Not found"),
                      subtitle: Text("Please add a Hymn to favorite!"),
                      onTap: () {},
                    ),
                  )
                ],
              );
            }
          },
        ));
  }*/
  Future<File> _writeData(String message) async {
    final file = await getApplicationDocumentsDirectory().then((dir) {
      return File("${dir.path}/HymnLyricsEnglish.json");
    });
    return file.writeAsString(message);
  }

  void updateFavorite(int index) async {
    jsonFile = await _localFile;
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      var temp = json.decode(jsonFile.readAsStringSync());

      var tempHymn =
          List<Hymns>.from(temp.map((i) => Hymns.fromJson(i))).toList();
      const int flag = 0;
      tempHymn[index].favorite = flag;
      _writeData(json.encode(tempHymn));
      setState(() {
        _favHymnList = tempHymn.where((val) {
          return val.favorite == 1;
        }).toList();
      });
    }
  }

  void snackBuilder(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Hymn ${indexOptimiser(_favHymnList[index].id)}${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
        ),
      ),
    );
  }

  void tabSnackBuilder(BuildContext context, int index) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      "Hymn ${indexOptimiser(_favHymnList[index].id)}${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
    )));
  }
}
