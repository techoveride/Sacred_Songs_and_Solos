import 'package:flutter/material.dart';
import 'package:hymn_book/util/main_details_screen.dart';

import '../ads/appopenadmanager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppOpenAdManager appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();

    //Load AppOpen Ad
    appOpenAdManager.loadAd();

    //Show AppOpen Ad After 8 Seconds
    Future.delayed(const Duration(milliseconds: 800)).then((value) {
      //Here we will wait for 8 seconds to load our ad
      //After 8 second it will go to HomePage
      appOpenAdManager.showAdIfAvailable();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MasterDetailsScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
