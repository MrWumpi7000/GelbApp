import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';

class StatisticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 2,
      child: Center(child: Text("Statistics Page")),
    );
  }
}
