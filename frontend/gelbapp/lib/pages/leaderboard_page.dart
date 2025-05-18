import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';

class LeaderboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 1,
      child: Center(child: Text("Leaderboard Page")),
    );
  }
}
