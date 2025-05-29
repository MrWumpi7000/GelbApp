import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/auth_service.dart';

class ReloadHandler with WidgetsBindingObserver {
  static final ReloadHandler _instance = ReloadHandler._internal();

  factory ReloadHandler() {
    return _instance;
  }

  ReloadHandler._internal();

  void init() {
    WidgetsBinding.instance.addObserver(this);
    if (kDebugMode) {
      print("ReloadHandler initialized.");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AuthService().refreshUserData();
    }
  }
}
