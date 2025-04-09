import 'package:flutter/material.dart';

class AppDecorations {
  static BoxDecoration cardShadow() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration gradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF5F5F5)],
      ),
    );
  }
}