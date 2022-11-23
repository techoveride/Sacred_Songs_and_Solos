import 'dart:async';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hymn_book/ads/anchored_adaptive_ad.dart';
import 'package:hymn_book/model/globals.dart' as globals;
import 'package:hymn_book/model/hymn.dart';
import 'package:hymn_book/util/fav_hymn_listing.dart';
import 'package:hymn_book/util/hymn_listing.dart';
import 'package:hymn_book/util/my_drawer.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/appopenadmanager.dart';
import '../main.dart' as main;
import 'fav_hymn_details.dart';
import 'hymn_details.dart';

// You can also test with your own ad unit IDs by registering your device as a
// test device. Check the logs for your device's ID value.
const String testDevice = '0D7F74813DAA8CF871287A05BE47FDE7';
const int maxFailedLoadAttempts = 3;
// const String testDevice = 'D3E0FD831CF53C8B3EA7798C1AD0128D';
final myTabbedPageKey = GlobalKey<_MasterDetailsScreenState>();

class MasterDetailsScreen extends StatefulWidget {
  const MasterDetailsScreen({super.key});

  @override
  _MasterDetailsScreenState createState() => _MasterDetailsScreenState();
}

class _MasterDetailsScreenState extends State<MasterDetailsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int currentTabIndex = 0;
  bool tabFlag = true;
  late TabController tabController;
  //Google Ads setup
  static const AdRequest request = AdRequest(
    nonPersonalizedAds: true,
  );
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  bool isTabletLayout = false;

  AppOpenAdManager appOpenAdManager = AppOpenAdManager();
  bool isPaused = false;

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            // ? 'ca-app-pub-2165165254805026/2118092023'
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (kDebugMode) {
              print('$ad loaded');
            }
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      if (kDebugMode) {
        print('Warning: attempt to show interstitial before loaded.');
      }
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void initState() {
//    themeMode();
    activeSearch = false;
    tabController =
        TabController(vsync: this, length: _kTabs.length, initialIndex: 0);
    super.initState();
    //ads Setup
    //Load AppOpen Ad
    appOpenAdManager.loadAd();
    WidgetsBinding.instance.addObserver(this);

    //load and show banner
    // loadBanner();
    //load Interstitial Ad
    loadInterstitial();
    tabController.addListener(() async {
      if (tabController.indexIsChanging) {
        await globals.player.stop();
      }
    });
    versionCheck();
  }

  @override
  void dispose() {
    tabController.dispose();
    // _bannerAd?.dispose();
    _interstitialAd?.dispose();
    main.isLightTheme.close();
    main.isLightTheme.close();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      isPaused = true;
    }
    if (state == AppLifecycleState.resumed && isPaused) {
      debugPrint("Resumed==========================");
      appOpenAdManager.showAdIfAvailable();
      isPaused = false;
    }
  } //End of Ads setup

  static const int tabletBreakpoint = 600;
  Hymns _selectedHymn = Hymns(
      id: 1,
      lyric:
          "Praise, my soul, the King of heaven ;\nTo His feet thy tribute bring ;\nRansomed, healed, restored, forgiven,\nWho like thee His praise shall sing ?\nPraise Him ! praise Him !\nPraise the everlasting King !\n \n2\n Praise Him for His grace and favour\nTo our fathers in distress ;\nPraise Him, still the same as ever,\nSlow to chide, and swift to bless :\nPraise Him ! praise Him !\nGlorious in His faithfulness !\n \n3\n Father- like He tends and spares us,\nWell our feeble frame He knows ;\nIn His hands He gently bears us,\nRescues us from all our foes :\nPraise Him ! praise Him !\nWidely as His mercy flows.\n \n4\n Angels, help us to adore Him,\nYe behold Him face to face !\nSun and moon, bow down before\nHim !Dwellers all in time and space,\nPraise Him ! praise Him !\nPraise with us the God of grace !\n",
      favorite: 0,
      tune: "",
      title: "Praise, my soul, the King of heaven");
  Hymns _favSelectedHymn = Hymns(
      id: -1,
      lyric: "Please select a hymn from the list",
      favorite: 0,
      tune: "",
      author: "",
      title: "No Hymn Selected !");
  bool activeSearch = false;
  final _searchController = TextEditingController();

  late Key searchBox;
  final _kTabs = <Tab>[
    const Tab(
      text: "All",
      icon: Icon(Icons.all_inclusive),
    ),
    const Tab(
      text: 'Favorite',
      icon: Icon(Icons.favorite),
    ),
  ];

  final GlobalKey<ScaffoldState> _mainDetailKey = GlobalKey();

/*
  Future<void> themeMode() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    bool status = preferences.getBool("nightMode");

    setState(() {
      if (status != null) globals.nightMode = status;
    });
  }
*/

  get _onBackPressed => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: const Center(child: Text("Are You Sure ?")),
            content: SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const Text("Do you want to exit"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            )),
                            overlayColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).splashColor)),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            )),
                            overlayColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).splashColor)),
                        onPressed: () {
                          SystemChannels.platform
                              .invokeMethod('SystemNavigator.pop');
                        },
                        child: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            elevation: 4.0,
            contentPadding: const EdgeInsets.all(10.0),
            shape: BeveledRectangleBorder(
                side: BorderSide(
                    color: Theme.of(context).splashColor, width: 1.0),
                borderRadius: BorderRadius.circular(8.0)),
          ));

  Widget _buildMobileFavLayout() {
    return FavHymnListing(
        key: favHymnGKey,
        hymnSelectedCallback: (hymnSelected) async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) {
            return FavHymnDetails(
              isInTabletLayout: false,
              hymns: hymnSelected,
              // adPadding: adPadding,
            );
          }));
        });
  }
  //.723.11.9

  Widget _buildTabFavLayout() {
    return Row(
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Material(
            elevation: 16.0,
            child: FavHymnListing(
              key: favHymnGKey,
              hymnSelectedCallback: (hymn) {
                setState(() {
                  _favSelectedHymn = hymn;
                });
              },
              hymnSelected: _favSelectedHymn,
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: FavHymnDetails(
            isInTabletLayout: true,
            hymns: _favSelectedHymn,
            // adPadding: adPadding,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return HymnListing(
      key: hymnGKey,
      hymnSelectedCallback: (hymnSelected) {
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) {
          return HymnDetails(
            isInTabletLayout: false,
            hymns: hymnSelected,
            // adPadding: adPadding,
          );
        }));
      },
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: <Widget>[
        Flexible(
          flex: 2,
          child: Material(
            elevation: 16.0,
            child: HymnListing(
              key: hymnGKey,
              hymnSelectedCallback: (hymn) {
                setState(() {
                  _selectedHymn = hymn;
                });
              },
              hymnSelected: _selectedHymn,
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: HymnDetails(
            isInTabletLayout: true,
            hymns: _selectedHymn,
            // adPadding: adPadding,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    Widget favContent;
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    var orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.portrait &&
        shortestSide < tabletBreakpoint) {
      //Mobile
      content = _buildMobileLayout();
      favContent = _buildMobileFavLayout();
      isTabletLayout = false;
    } else {
      //tablet
      content = _buildTabletLayout();
      favContent = _buildTabFavLayout();
      isTabletLayout = true;
    }
    final _kTabPages = <Widget>[
      content,
      favContent,
    ];

    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        onWillPop: () {
          if (activeSearch) {
            _searchController.clear();
            if (hymnGKey.currentState != null) {
              hymnGKey.currentState!.onSearchExit(" ");
            } else if (hymnGKey.currentState == null) {
              favHymnGKey.currentState!.onSearchExit(" ");
            }
            setState(() {
              activeSearch = false;
            });
            setState(() {
              activeSearch = false;
            });
            return Future(() => false);
          } else {
            return _onBackPressed;
          }
        },
        child: Scaffold(
          key: _mainDetailKey,
          appBar: _appBar(),
          body: TabBarView(controller: tabController, children: _kTabPages),
          drawer: MyDrawer(
            isTabletLayout: isTabletLayout,
            // destroyBanner: destroyBanner,
            // buildBanner: buildBanner,
          ),
          bottomNavigationBar:
              isTabletLayout ? const AnchoredAdaptiveAd() : null,
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    if (activeSearch) {
      return AppBar(
        leading: const Icon(Icons.search),
        title: TextField(
          key: searchBox,
          controller: _searchController,
          autofocus: true,
          onChanged: onItemChanged,
          decoration: const InputDecoration(
              hintText: "Search Hymn",
              hintStyle: TextStyle(color: Colors.white70)),
        ),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                if (hymnGKey.currentState != null) {
                  hymnGKey.currentState!.onSearchExit(" ");
                } else if (hymnGKey.currentState == null) {
                  favHymnGKey.currentState!.onSearchExit(" ");
                }

                setState(() {
                  activeSearch = false;
                });
              })
        ],
      );
    } else {
      return AppBar(
        title: const Text("Sacred Songs & Solos"),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            isTabletLayout
                ? Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.all_inclusive),
                        ),
                        Text('All')
                      ],
                    ),
                  )
                : const Tab(
                    text: "All",
                    icon: Icon(Icons.all_inclusive),
                  ),
            isTabletLayout
                ? Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.favorite),
                        ),
                        Text('Favorite')
                      ],
                    ),
                  )
                : const Tab(
                    text: "Favorite",
                    icon: Icon(Icons.favorite),
                  )

//            Tab(
////              text: ".",
//                child: isTabletLayout
//                    ? Row(
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          Padding(
//                            padding: const EdgeInsets.only(right: 8.0),
//                            child: const Icon(Icons.all_inclusive),
//                          ),
//                          const Text("All")
//                        ],
//                      )
//                    : Column(
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          const Text("All"),
//                          const Icon(Icons.all_inclusive),
//                        ],
//                      )),
//            Tab(
//                child: isTabletLayout
//                    ? Row(
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          Padding(
//                            padding: const EdgeInsets.only(right: 8.0),
//                            child: const Icon(Icons.favorite),
//                          ),
//                          const Text("Favorite")
//                        ],
//                      )
//                    : Column(
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          const Text("Favorite"),
//                          const Icon(Icons.favorite),
//                        ],
//                      )),
          ],
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.sort), onPressed: () => sortList()),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() => activeSearch = true);
            },
          )
        ],
      );
    }
  }

  void onItemChanged(String value) {
    hymnGKey.currentState != null
        ? hymnGKey.currentState!.onSearchedItem(value)
        : favHymnGKey.currentState!.onSearchedItem(value);
  }

  sortList() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Sort By..."),
              content: SizedBox(
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.sort_by_alpha),
                        title: const Text(
                          "Title",
                          style: TextStyle(fontSize: 12.0),
                        ),
                        onTap: () {
                          hymnGKey.currentState != null
                              ? hymnGKey.currentState!.sortByTitle()
                              : favHymnGKey.currentState!.sortByTitle();
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        leading: const Icon(Icons.format_list_numbered),
                        title: const Text(
                          "Number",
                          style: TextStyle(fontSize: 12.0),
                        ),
                        onTap: () {
                          hymnGKey.currentState != null
                              ? hymnGKey.currentState!.sortByNumber()
                              : favHymnGKey.currentState!.sortByNumber();
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              elevation: 4.0,
              contentPadding: const EdgeInsets.all(10.0),
              shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(26.0)),
            ));
  }

  // void loadBanner() {
  //   _bannerAd = createBannerAd();
  //   _bannerAd?.load();
  // }

  void loadInterstitial() {
    _createInterstitialAd();
    //show interstitial timer
    Timer(const Duration(seconds: 60), () {
      _showInterstitialAd();
    });
  }

  // destroyBanner() async {
  //   await _bannerAd?.dispose();
  //   _bannerAd = null;
  //   setState(() => adPadding = 0.0);
  // }

  // buildBanner() {
  //   loadBanner();
  // }

  void versionCheck() async {
    //Get Current installed version of app
    final PackageInfo info = await PackageInfo.fromPlatform();
    double currentVersion =
        double.parse(info.version.trim().replaceAll(".", ""));
    globals.app_version = info.version.trim().replaceAll(".", "");
    //Get Latest version info from firebase config
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    try {
      // Using default duration to force fetching from remote server.
      // await remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await remoteConfig.fetchAndActivate();
      String remoteVersion = remoteConfig.getString("app_version");
      String shareApp = remoteConfig.getString("share_app");
      String moreApps = remoteConfig.getString("more_apps");
      String proStoreUrl = remoteConfig.getString("pro_store_url");
      String proPlayUrl = remoteConfig.getString("pro_play_url");
      globals.PREMIUM_APP_STORE_URL = proStoreUrl;
      globals.PREMIUM_PLAY_STORE_URL = proPlayUrl;
      globals.share_app = shareApp;
      globals.more_apps = moreApps;
      globals.app_update = remoteVersion;
      double newVersion =
          double.parse(remoteVersion.trim().replaceAll(".", ""));
      if (newVersion > currentVersion) {
        _showVersionDialog();
      }
    } catch (exception) {
      if (kDebugMode) {
        print('Unable to fetch remote config. Cached or default values will be '
            'used\nException: $exception');
      }
    }
  }

  _showVersionDialog() async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "New Update Available";
        String message =
            "There is a newer version of app available please update it now.";
        String btnLabel = "Update Now";
        String btnLabelCancel = "Later";
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnLabel),
                    onPressed: () => _launchURL(globals.PREMIUM_APP_STORE_URL),
                  ),
                  TextButton(
                    child: Text(btnLabelCancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnLabel),
                    onPressed: () => _launchURL(globals.PREMIUM_PLAY_STORE_URL),
                  ),
                  TextButton(
                    child: Text(btnLabelCancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
      },
    );
  }

  _launchURL(String myUrl) async {
    Uri url = Uri.parse(myUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}

void setTheme(bool mode) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setBool("nightMode", mode);
  globals.nightMode = mode;
}
