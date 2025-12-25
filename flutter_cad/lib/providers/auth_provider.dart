import 'package:flutter/material.dart';
import '../services/mock_service.dart';

class AuthProvider extends ChangeNotifier {
  final MockService _service;
  bool _isAuthenticated = false;

  AuthProvider(this._service);

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    final success = await _service.login(email, password);
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
