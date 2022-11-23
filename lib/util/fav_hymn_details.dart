import 'dart:async';
import 'dart:io';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/model/hymn.dart';
import 'package:share/share.dart';

GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
GlobalKey<_FavHymnDetailsState> favHymnDetailKey = GlobalKey();

class FavHymnDetails extends StatefulWidget {
  final bool isInTabletLayout;
  final Hymns hymns;
  // final double? adPadding;
  FavHymnDetails({
    Key? key,
    required this.isInTabletLayout,
    required this.hymns,
  }) : super(key: key);

  @override
  _FavHymnDetailsState createState() => _FavHymnDetailsState();
}

class _FavHymnDetailsState extends State<FavHymnDetails> {
  late File jsonFile;
  late Directory dir;
  String fileName = "HymnLyricsEnglish.json";
  bool fileExists = false;
  var hymn;

  int hymnSize = 0;

  late IconData favIcon;
  late StreamSubscription audioPlayerStateSubs;
  late String mp3Uri;

  double? barHeight;
  bool tuneIconVisibility = true;
  late ScrollController _scrollController;

//load Audio file
  void initAudioPlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //do something
    });

    audioPlayerStateSubs =
        globals.player.onPlayerStateChanged.listen((listener) async {
      if (listener == AudioPlayerState.PLAYING) {
        if (kDebugMode) {
          print("Tune playing");
        }
      } else if (listener == AudioPlayerState.STOPPED) {
        await stopPlayer();
        if (kDebugMode) {
          print("Tune Stopped");
        }
      } else if (listener == AudioPlayerState.COMPLETED) {
        widget.isInTabletLayout
            ? tabOnCompletedSnackbar(context)
            : onCompletedSnackbar();
      } else if (listener == AudioPlayerState.PAUSED) {
        if (kDebugMode) {
          print("Tune Paused");
        }
      }
    }, onError: (error) async {
      globals.playerState = AudioPlayerState.STOPPED;
      await stopPlayer();
      widget.isInTabletLayout ? audioTabSnackBuilder() : audioSnackBuilder();
      if (kDebugMode) {
        print("AudioPlayer Subscription error $error");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
    _scrollController = ScrollController();
  }

  /*_loadBgColor() async {
    SharedPreferences bgColorPref = await SharedPreferences.getInstance();
    var color = bgColorPref.getInt("bgColor");
    setState(() {
      if (color != null) globals.bgColor = Color(color);
    });
  }

  _loadTxtColor() async {
    SharedPreferences txtColorPref = await SharedPreferences.getInstance();
    var color = txtColorPref.getInt("txtColor");
    setState(() {
      if (color != null) globals.txtColor = Color(color);
    });
  }

  _loadFontSize() async {
    SharedPreferences fontSizePref = await SharedPreferences.getInstance();
    var size = fontSizePref.getDouble("fontSize");
    setState(() {
      if (size != null)
        globals.fontSize = size;
      else
        globals.fontSize = 18.0;
    });
  }

  _loadLineSp() async {
    SharedPreferences lineSpPref = await SharedPreferences.getInstance();
    var size = lineSpPref.getDouble("lineSp");
    setState(() {
      if (size != null) globals.lineSp = size;
    });
  }
*/
  @override
  void dispose() {
    audioPlayerStateSubs.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  /*Future<List<Hymns>> getHymn() async {
    jsonFile = await getApplicationDocumentsDirectory()
        .then((dir) => File("${dir.path}/$fileName"));
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      hymn = json.decode(jsonFile.readAsStringSync());
      setState(() {
        _favHymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
        hymnSize = _favHymnList.length;
      });
    }
//    favInit();
    return _favHymnList;
  }*/

  /* Future<File> _writeData(String message) async {
    final file = await getApplicationDocumentsDirectory().then((dir) {
      return File("${dir.path}/HymnLyricsEnglish.json");
    });
    return file.writeAsString('$message');
  }*/

/*  void updateFavorite(int index, int flag) {
//    listHymns = _favHymnList;
//    listHymns[index].favorite = flag;
//    _writeData(json.encode(listHymns));
  }*/

  @override
  Widget build(BuildContext context) {
//Mobile view content
    final Widget content = ListView(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                  widget.hymns.title
                      .substring(widget.hymns.title.indexOf('-') + 1),
                  textAlign: TextAlign.center,
                  style: globals.titleStyle()),
              subtitle: Text(
                "Hymn~"
                "${widget.hymns.id}"
                /* widget.hymns != null
                    ? '\n${widget.hymns.author}' +
                        "\n${widget.hymns.tune.isNotEmpty ? widget.hymns.tune : ''}"
                    : */
                '',
                textAlign: TextAlign.center,
                style: globals.subheadStyle(),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(lyricOptimiser(widget.hymns.lyric),
                textAlign: TextAlign.center, style: globals.lyricStyle()),
          ),
        ),
      ],
    );
    //Tab view content
    final Widget tabContent = ListView(
      children: <Widget>[
        Center(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(widget.hymns.title,
                    textAlign: TextAlign.center, style: globals.titleStyle()),
                subtitle: Text(
                  "Hymn~"
                  "${(widget.hymns.id)}"
                  // '\n${widget.hymns.author}'
                  // "\n${widget.hymns.tune!.isNotEmpty ? widget.hymns.tune : ''}",
                  ,
                  textAlign: TextAlign.center,
                  style: globals.titleStyle(),
                ),
              )),
        ),
        Center(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(lyricOptimiser(widget.hymns.lyric),
                  textAlign: TextAlign.center, style: globals.lyricStyle())),
        ),
      ],
    );

    if (widget.isInTabletLayout) {
      return Scaffold(
        body: Container(
          color: globals.nightMode == false ? globals.bgColor : Colors.black45,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: tuneIconVisibility ? 1.0 : 0.0,
                    child: SizedBox(
                        height: barHeight ?? 36.0,
                        child: Card(
                          margin: const EdgeInsets.all(0.0),
                          elevation: 4.0,
                          clipBehavior: Clip.none,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                  icon: Icon(
                                    globals.tuneIcon,
                                    color: Theme.of(context).cardColor,
                                  ),
                                  onPressed: () async {
                                    if (globals.isPlaying) {
                                      await pausePlayer();
                                      audioTabSnackBuilder();
                                    } else {
                                      await globals.playSound();
                                      setState(() {
                                        globals.tuneIcon = globals.pause;
                                        globals.playerState =
                                            AudioPlayerState.PLAYING;
                                      });
                                      audioTabSnackBuilder();
                                    }
                                  }),
                              IconButton(
                                  icon: Icon(globals.stop,
                                      color: Theme.of(context).cardColor),
                                  onPressed: () async {
                                    await stopPlayer();
                                    audioTabSnackBuilder();
                                  }),
                            ],
                          ),
                        )),
                  ),
                  Flexible(
                      child: NotificationListener<ScrollNotification>(
                          onNotification: (status) {
                            if (status is ScrollUpdateNotification) {
                              if (status.scrollDelta! > 0) {
//                                Future.delayed(Duration(seconds: 2), () {
                                hideTabTuneBar(true);
//                                });
                              } else {
//                                Future.delayed(Duration(seconds: 2), () {
                                hideTabTuneBar(false);
//                                });
                              }
                            }
                            return false;
                          },
                          child: tabContent)),
                ],
              ),
            ),
          ),
        ),
//        bottomNavigationBar: Container(
//          height: widget.adPadding,
//        ),
        floatingActionButton: Visibility(
          visible: widget.hymns.id == -1 ? false : true,
          child: FloatingActionButton(
              onPressed: () => shareIntent(),
              mini: true,
              child: const Icon(Icons.share)),
        ),
      );
    }

    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              await stopPlayer();
              Future.delayed(const Duration(milliseconds: 1), () {
                Navigator.of(context).pop();
              });
            }),
        title: Text(widget.hymns.title),
        actions: <Widget>[
          IconButton(
              icon: Icon(globals.tuneIcon),
              onPressed: () async {
                if (globals.isPlaying) {
                  await pausePlayer();
                  audioSnackBuilder();
                } else {
                  await globals.playSound();
                  setState(() {
                    globals.tuneIcon = globals.pause;
                    globals.playerState = AudioPlayerState.PLAYING;
                  });
                  audioSnackBuilder();
                }
              }),
          IconButton(
              icon: Icon(globals.stop),
              onPressed: () async {
                await stopPlayer();
                audioSnackBuilder();
              }),
        ],
      ),
//      backgroundColor: Colors.deepPurpleAccent,

      body: WillPopScope(
        // ignore: missing_return
        onWillPop: () async {
          if (globals.playerState == AudioPlayerState.PLAYING) {
            stopPlayer();
            return false;
          } else {
            Navigator.of(context).pop();
            return true;
          }
        },
        child: Container(
          color: globals.nightMode == false ? globals.bgColor : Colors.black45,
//        decoration: mainBoxStyle(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: content,
            ),
          ),
        ),
      ),
//      bottomNavigationBar: Container(
//        height: widget.adPadding,
//      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => shareIntent(),
        child: const Icon(Icons.share),
      ),
    );
  }

  shareIntent() {
    Share.share(
        "Title:${widget.hymns.title}\n${widget.hymns.lyric}\nhttps://play.google.com/store/apps/details?id=com.hymnestry.hymn_book&hl=en&gl=US",
        subject: widget.hymns.title);
  }

  String indexOptimiser(int id) {
    String output;
    if (id.toString().length == 1) {
      output = "000" "${id.toString()}";
      return output;
    } else if (id.toString().length == 2) {
      output = "00" "${id.toString()}";
      return output;
    } else if (id.toString().length == 3) {
      output = "0" "${id.toString()}";
      return output;
    } else {
      return id.toString();
    }
  }

  String lyricOptimiser(String lyric) {
    if (lyric.substring(0, 1).contains('1')) {
      return lyric;
    } else {
      return "1\n$lyric";
    }
  }

  Future stopPlayer() async {
    await globals.player.stop();
    setState(() {
      globals.tuneIcon = globals.play;
      globals.playerState = AudioPlayerState.STOPPED;
    });
  }

  Future pausePlayer() async {
    await globals.player.pause();
    setState(() {
      globals.tuneIcon = globals.play;
      globals.playerState = AudioPlayerState.PAUSED;
    });
  }

  void audioSnackBuilder() {
    String popUp;
    if (globals.playerState == AudioPlayerState.PLAYING) {
      popUp = "Tune Playing";
    } else if (globals.playerState == AudioPlayerState.STOPPED) {
      popUp = "Tune Stopped";
    } else {
      popUp = "Tune Paused";
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          popUp,
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 500),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  void audioTabSnackBuilder() {
    String popUp;
    if (globals.playerState == AudioPlayerState.PLAYING) {
      popUp = "Tune Playing";
    } else {
      if (globals.playerState == AudioPlayerState.STOPPED) {
        popUp = "Tune Stopped";
      } else {
        popUp = "Tune Paused";
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        popUp,
        textAlign: TextAlign.center,
      ),
      duration: const Duration(milliseconds: 500),
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ));
  }

  void tabOnCompletedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          "Tune Completed",
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 500),
        shape:
            BeveledRectangleBorder(borderRadius: BorderRadius.circular(8.0))));
  }

  void onCompletedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          "Tune Completed",
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 500),
        shape:
            BeveledRectangleBorder(borderRadius: BorderRadius.circular(8.0))));
  }

  void hideTabTuneBar(bool flag) {
    setState(() {
      if (flag == true) {
        barHeight = 0.0;
        tuneIconVisibility = false;
      } else {
        barHeight = 36.0;
        tuneIconVisibility = true;
      }
    });
  }

/*
  void snackBuilder(int index) {
    scaffoldState.currentState.showSnackBar(
      SnackBar(
        content: Text(
          "Hymn ${_favHymnList[index].title.substring(0, 3)}" +
              "${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
        ),
      ),
    );
  }

  void tabSnackBuilder(BuildContext context, int index) {
    Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(
      "Hymn ${_favHymnList[index].title.substring(0, 3)}" +
          "${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
    )));
  }
*/

//  void favInit() {
//    int id = widget.hymns.id - 1;
//    if (_favHymnList[id].favorite == 1) {
//      favIcon = _on;
//    } else {
//      favIcon = _off;
//    }
//  }
}
