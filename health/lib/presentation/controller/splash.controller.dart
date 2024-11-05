// splash.controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/home.dart';

class SplashController {
  final BuildContext context;

  SplashController(this.context);

  void startTimer() {
    Timer(Duration(seconds: 10), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Home()),
      );
    });
  }
}
