/*
import 'package:flutter/cupertino.dart';

import '../datasources/Userdetailsservice.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
    ApiService().setAuthToken(token);
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    ApiService().setAuthToken('');
    notifyListeners();
  }
}*/
