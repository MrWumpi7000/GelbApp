import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 0,
      child: Center(child: Text("Home Page")),
    );
  }
}
