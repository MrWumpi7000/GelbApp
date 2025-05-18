import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      child: Center(child: Text("Profile Page")),
    );
  }
}
