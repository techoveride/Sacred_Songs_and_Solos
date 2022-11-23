import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'hymn.dart';
import 'hymn_list.dart';

//global variables
double fontSize = 0.0;
Color bgColor = Colors.transparent;
Color txtColor = Colors.black;
double lineSp = 0.0;
bool nightMode = false;
IconData tuneIcon = play;
IconData play = Icons.play_circle_outline;
IconData pause = Icons.pause_circle_outline;
IconData stop = Icons.stop;
ThemeData themeMode = defaultTheme();
//webView State
bool isLoaded = false;
//remote config variables
String app_update = "";
String app_version = "";
String more_apps = 'https://hymnestry.com/';
String share_app = 'https://hymnestry.com/';
String APP_STORE_URL =
    'https://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=com.hymnestry.hymn_book&mt=8';
String PLAY_STORE_URL =
    'https://play.google.com/store/apps/details?id=com.hymnestry.hymn_book';
String PREMIUM_APP_STORE_URL =
    'https://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=com.hymnestry.hymn_book&mt=8';
String PREMIUM_PLAY_STORE_URL =
    'https://play.google.com/store/apps/details?id=com.hymnestry.hymn_book';

late List<Hymns> defaultHymn;
const fileName = "HymnLyricsEnglish_v1.json";

// String _fontFamily = 'Courier Prime';
double _subheadFont = 16.0;
double _titleFontSize = 30.0;

//default theme
ThemeData defaultTheme() {
  return ThemeData(
      splashColor: Colors.deepOrangeAccent,
      indicatorColor: Colors.deepOrangeAccent,
      // fontFamily: _fontFamily,
      textTheme: const TextTheme(
          headline1: TextStyle(fontWeight: FontWeight.w400),
          headline2: TextStyle(fontWeight: FontWeight.w400),
          subtitle1: TextStyle(fontWeight: FontWeight.w400),
          subtitle2: TextStyle(fontWeight: FontWeight.w400)),
      colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepOrange,
              accentColor: Colors.orangeAccent)
          .copyWith(secondary: Colors.orange));
}

TextStyle titleStyle() {
  return TextStyle(
      // fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: _titleFontSize,
      color: nightMode == false ? txtColor : Colors.white);
}

TextStyle subheadStyle() {
  return TextStyle(
      // fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: _subheadFont,
      color: nightMode == false ? txtColor : Colors.white);
}

TextStyle lyricStyle() {
  return TextStyle(
      // fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      height: lineSp,
      color: nightMode == false ? txtColor : Colors.white);
}

AudioPlayer player = AudioPlayer();
AudioPlayerState playerState = AudioPlayerState.STOPPED;

get isPlaying => playerState == AudioPlayerState.PLAYING;

get isPaused => playerState == AudioPlayerState.PAUSED;
String mp3Uri = "";
bool fileExists = false;

Future<void> load(String song) async {
  String result;
  String output;
  // Directory dir = await getApplicationDocumentsDirectory();

  String tune = tunes.where((val) {
    result = val.substring(val.indexOf('a') + 1, val.indexOf('.')).trim();
    return int.parse(song) == int.parse(result);
  }).toString();

  //checking if tune is loaded
  await getApplicationDocumentsDirectory().then((dir) async {
    output = tune.substring(1, tune.indexOf(')'));
    File file = File('${dir.path}/$output');
    fileExists = file.existsSync();
    if (fileExists) {
      debugPrint("Tune Already Loaded");
      mp3Uri = file.uri.toString();
    } else {
      //loading tune from file
      try {
        final ByteData data = await rootBundle.load('tunes/$output');
        File file = File('${dir.path}/$output');
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
        mp3Uri = file.uri.toString();
        debugPrint('finished loading, uri=$mp3Uri');
      } catch (e) {
        debugPrint("Failed to load the file because: $e");
        output = 'default.mp3';
        final ByteData data = await rootBundle.load('tunes/$output');
        File file = File('${dir.path}/$output');
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
        mp3Uri = file.uri.toString();
        debugPrint('Default loaded, uri=$mp3Uri');
      }
    }
  });
}

Future playSound() async {
  // print("mp3 uri : $mp3Uri");
  if (mp3Uri.isNotEmpty) {
    // await player.play(
    //     'https://www.smallchurchmusic.com/2011/MP3/MP3-ChristIsComing-BrynCalfaria-PipeA-128-CAM.mp3');
    await player.play(mp3Uri);
  }
}
