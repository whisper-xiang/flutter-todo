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

  // 用于跳过登录直接设置认证状态的方法
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }
}
