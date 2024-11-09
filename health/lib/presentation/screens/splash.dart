// splash.dart
import 'package:flutter/material.dart';
import 'package:health/main.dart';
import 'package:health/presentation/controller/splash.controller.dart';

class Splash extends StatefulWidget {


  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController(context);
    _controller.startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/Brand.png'), // Display the image
      ),
    );
  }
}
