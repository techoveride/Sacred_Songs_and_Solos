import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hymn_book/ads/anchored_adaptive_ad.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/util/main_details_screen.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'model/hymn.dart';

//local variables
late File jsonFile;
bool fileExists = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      testDeviceIds: [
        'A1D024014755730901F48A2A06933E1F',
        '0D7F74813DAA8CF871287A05BE47FDE7'
      ]));
  // testDeviceIds: ['0D7F74813DAA8CF871287A05BE47FDE7']));

  //Checks if Hymn File Storage is Created
  await getApplicationDocumentsDirectory().then((directory) async {
    jsonFile = File(join(directory.path, 'HymnLyricsEnglish.json'));
    fileExists = jsonFile.existsSync();
    if (fileExists) {
      debugPrint("File Already Created");
      //Loads hymns from bootup
      var hymn = json.decode(jsonFile.readAsStringSync());
      globals.defaultHymn =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
      //load finished
    } else {
      debugPrint("Creating and Writing to File");
      final file = await getApplicationDocumentsDirectory().then((dir) {
        return File(join(dir.path, 'HymnLyricsEnglish.json'));
      });
      file.writeAsStringSync(json.encode(listHymns));
      //Loads hymns from bootup
      var hymn = json.decode(jsonFile.readAsStringSync());
      globals.defaultHymn =
          List<Hymns>.from(hymn.map((i) => Hymns.fromJson(i)));
      //load finished
    }
  });

  //Loads the theme mode of the before bootup
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool? status = preferences.getBool("nightMode");
  if (status != null) {
    globals.nightMode = status;
  } else {
    globals.nightMode = false;
  }
  //load hymn Details prefs
  var colorBg = preferences.getInt("bgColor");
  if (colorBg != null) {
    globals.bgColor = Color(colorBg);
  } else {
    globals.bgColor = Colors.white;
  }

  var colorText = preferences.getInt("txtColor");
  if (colorText != null) {
    globals.txtColor = Color(colorText);
  } else {
    globals.txtColor = Colors.black;
  }

  var sizeFont = preferences.getDouble("fontSize");
  if (sizeFont != null) {
    globals.fontSize = sizeFont;
  } else {
    globals.fontSize = 18.0;
  }

  var sizeLineSp = preferences.getDouble("lineSp");
  if (sizeLineSp != null) {
    globals.lineSp = sizeLineSp;
  } else {
    globals.lineSp = 1.2;
  }

  runApp(const MyApp());
}

/*ThemeData _defaultTheme() {
  return ThemeData(
      primarySwatch: Colors.deepOrange,
      accentColor: Colors.orange,
      splashColor: Colors.deepOrangeAccent,
      // fontFamily: _fontFamily,
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w400),
          subhead: TextStyle(fontWeight: FontWeight.w400),
          title: TextStyle(fontWeight: FontWeight.w400),
          subtitle: TextStyle(fontWeight: FontWeight.w400)));
}

setTheme(bool mode) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setBool("nightMode", mode);

 mode == true
      ? _themeMode = ThemeData.dark()
      : _themeMode = _defaultTheme();
}*/

StreamController<bool> isLightTheme = StreamController();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        initialData: globals.nightMode,
        stream: isLightTheme.stream,
        builder: (context, snapshot) {
          return MaterialApp(
              theme: snapshot.data! ? ThemeData.dark() : globals.defaultTheme(),
              debugShowCheckedModeBanner: false,
              builder: (context, ads) {
                return Column(
                  children: [
                    Expanded(child: ads!),
                    const AnchoredAdaptiveAd(),
                  ],
                );
              },
              home: const MasterDetailsScreen());
        });
  }
}
