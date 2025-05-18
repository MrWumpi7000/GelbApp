import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProtectedPage extends StatelessWidget {
  final Widget child;

  const ProtectedPage({super.key, required this.child});

  Future<bool> _hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(); // Could be a loading spinner or splash screen
        }

        if (snapshot.data == false) {
          // Redirect to login if no token
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox();
        }

        return child;
      },
    );
  }
}
