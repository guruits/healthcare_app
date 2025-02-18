import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health/presentation/screens/home.dart';
import 'package:health/presentation/screens/start.dart';

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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authLogin.isAuthenticated ? Start() : Home(),
        ),
      );
    });
  }
}