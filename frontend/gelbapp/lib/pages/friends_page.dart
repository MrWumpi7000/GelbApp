import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';

class FriendsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 1,
      child: Center(child: Text("Friends Page")),
    );
  }
}
