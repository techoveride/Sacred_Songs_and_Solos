import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/model/hymn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

import '../ads/applifecyclereactor.dart';
import '../ads/appopenadmanager.dart';

GlobalKey<_HymnDetailsState> hymnDetailKey = GlobalKey();

class HymnDetails extends StatefulWidget {
  final bool isInTabletLayout;
  final Hymns hymns;
  final double? adPadding;

  HymnDetails(
      {required this.isInTabletLayout, required this.hymns, this.adPadding});

  @override
  _HymnDetailsState createState() => _HymnDetailsState();
}

class _HymnDetailsState extends State<HymnDetails> with WidgetsBindingObserver {
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  GlobalKey<ScaffoldState> tabViewScaffold = GlobalKey();

  late File jsonFile;
  late Directory dir;
  bool fileExists = false;
  var hymn;
  List<Hymns>? _hymnList;

  int hymnSize = 0;

  IconData? favIcon;

  final IconData _off = Icons.favorite_border;
  final IconData _on = Icons.favorite;

  late StreamSubscription audioPlayerStateSubs;
  late String mp3Uri;

  double? barHeight;
  bool tuneIconVisibility = true;
  late ScrollController _scrollController;

  //AppOpenAds
  AppOpenAdManager appOpenAdManager = AppOpenAdManager();
  late AppLifecycleReactor _appLifecycleReactor;

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
        if (kDebugMode) {
          print("Tune Stopped");
        }
      } else if (listener == AudioPlayerState.COMPLETED) {
        if (kDebugMode) {
          print("Tune Completed");
        }
        await globals.player.stop();
        setState(() {
          globals.tuneIcon = globals.play;
          globals.playerState = AudioPlayerState.COMPLETED;
        });
        widget.isInTabletLayout
            ? tabOnCompletedSnackbar()
            : onCompletedSnackbar();
      } else if (listener == AudioPlayerState.PAUSED) {
        debugPrint("Tune Paused");
      }
    }, onError: (error) async {
      await stopPlayer();
      widget.isInTabletLayout ? audioTabSnackBuilder() : audioSnackBuilder();
      debugPrint("AudioPlayer Subscription error $error");
    });
  }

  @override
  void initState() {
    initAudioPlayer();
    _scrollController = ScrollController();
    getHymn();
    //App Open Ads
    appOpenAdManager = AppOpenAdManager()..loadAd();
    _appLifecycleReactor =
        AppLifecycleReactor(appOpenAdManager: appOpenAdManager);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState;
    _appLifecycleReactor.listenToAppStateChanges();
  }

  @override
  void dispose() {
    audioPlayerStateSubs.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<File> _writeData(String message) async {
    final file = await getApplicationDocumentsDirectory().then((dir) {
      return File("${dir.path}/${globals.fileName}");
    });
    return file.writeAsString(message);
  }

  void updateFavorite(int index, int flag) {
    listHymns = _hymnList!;
    listHymns[index].favorite = flag;
    _writeData(json.encode(listHymns));
  }

  Future<List<Hymns>?> getHymn() async {
    jsonFile = await getApplicationDocumentsDirectory()
        .then((dir) => File("${dir.path}/${globals.fileName}"));
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      hymn = json.decode(jsonFile.readAsStringSync());
      setState(() {
        _hymnList = List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
        hymnSize = _hymnList!.length;
      });
    }
    favInit();
    return _hymnList;
  }

  @override
  Widget build(BuildContext context) {
    favInit();
    final Widget content = ListView(
      children: <Widget>[
        Center(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(widget.hymns.title,
                    textAlign: TextAlign.center, style: globals.titleStyle()),
                subtitle: Text(
                  "Hymn~"
                  "${(widget.hymns.id)}",
                  // "\n${widget.hymns.author}"
                  // "\n${widget.hymns.tune}",
                  // "\n${widget.hymns.tune!.isNotEmpty ? widget.hymns.tune : ''}",
                  textAlign: TextAlign.center,
                  style: globals.subheadStyle(),
                ),
              )),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              lyricOptimiser(widget.hymns.lyric),
              textAlign: TextAlign.center,
              style: globals.lyricStyle(),
            ),
          ),
        ),
      ],
    );

    //content view for tablets
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
                  "${(widget.hymns.id)}",
                  // "\n${widget.hymns.author}"
                  // "\n${widget.hymns.tune}",
                  // "\n${widget.hymns.tune!.isNotEmpty ? widget.hymns.tune : ''}",
                  textAlign: TextAlign.center,
                  style: globals.titleStyle(),
                ),
              )),
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

    if (widget.isInTabletLayout) {
      return Scaffold(
        key: tabViewScaffold,
        body: Container(
          color: globals.nightMode == false ? globals.bgColor : Colors.black45,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
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
                                  // sound.AudioPlayer aud = sound.AudioPlayer();
                                  // aud.play('https://www.smallchurchmusic.com/2011/MP3/MP3-KindMaker-JesuDulcisMemoria-SPiano-128-CAM.mp3');
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
        floatingActionButton: Visibility(
          visible: widget.hymns.id == -1 ? false : true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: FloatingActionButton(
                  onPressed: () {
                    int index = _hymnList![widget.hymns.id - 1].id - 1;
                    setState(() {
                      if (favIcon == _off) {
                        favIcon = _on;
                        updateFavorite(index, 1);
                      } else {
                        favIcon = _off;
                        updateFavorite(index, 0);
                      }
                    });
                    tabSnackBuilder(context, index);
                  },
                  mini: true,
                  heroTag: 'favBtn',
                  child: Icon(favIcon),
                ),
              ),
              FloatingActionButton(
                onPressed: () => shareIntent(),
                mini: true,
                heroTag: 'shareBtn',
                child: const Icon(Icons.share),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // key: scaffoldState,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await stopPlayer();
            Future.delayed(const Duration(milliseconds: 1), () {
              Navigator.of(context).pop();
            });
          },
        ),
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
          IconButton(
              icon: Icon(favIcon),
              onPressed: () {
                int index = _hymnList![widget.hymns.id - 1].id - 1;
                setState(() {
                  if (favIcon == _off) {
                    favIcon = _on;
                    updateFavorite(index, 1);
                  } else {
                    favIcon = _off;
                    updateFavorite(index, 0);
                  }
                });
                snackBuilder(index);
              }),
        ],
      ),
//      backgroundColor: Colors.deepPurpleAccent,

      body: WillPopScope(
        // ignore: missing_return
        onWillPop: () async {
          if (globals.playerState == AudioPlayerState.PLAYING) {
            await stopPlayer();
            return false;
          } else {
            Navigator.of(context).pop();
            return true;
          }
        },
        child: Container(
          color: globals.nightMode == false ? globals.bgColor : Colors.black45,
          // decoration: mainBoxStyle(),
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

  void snackBuilder(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Hymn ${indexOptimiser(_hymnList![index].id)}${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
        ),
      ),
    );
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

  String lyricOptimiser(String lyric) {
    if (lyric.substring(0, 1).contains('1')) {
      return lyric;
    } else {
      return "1\n$lyric";
    }
  }

  void tabSnackBuilder(BuildContext context, int index) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
      "Hymn ${indexOptimiser(_hymnList![index].id)}${favIcon == _on ? ' added to favorites' : ' removed from favorites'}",
    )));
  }

  void favInit() {
    if (_hymnList != null) {
      int id = _hymnList![widget.hymns.id - 1].id - 1;
      if (_hymnList![id].favorite == 1) {
        favIcon = _on;
      } else {
        favIcon = _off;
      }
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
    } else if (globals.playerState == AudioPlayerState.STOPPED) {
      popUp = "Tune Stopped";
    } else {
      popUp = "Tune Paused";
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

  void tabOnCompletedSnackbar() {
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
}
