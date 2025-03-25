import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home.dart';
import '../screens/start.dart';
import 'login.controller.dart';

class SplashController {
  final BuildContext context;

  SplashController(this.context);

  void startTimer() {
    Timer(Duration(seconds: 5), () async {
      final authLogin = Provider.of<AuthLogin>(context, listen: false);
      await authLogin.init();

      // Navigate based on authentication state
      if (!context.mounted) return;

      if (authLogin.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Start()),
        );
      } else {
        // If token expired or user not authenticated, send to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Home()),
        );
      }
    });
  }
}