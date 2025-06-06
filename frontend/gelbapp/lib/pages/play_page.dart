import 'package:flutter/material.dart';

class PlayPage extends StatelessWidget {
  final int roundId;

  const PlayPage({required this.roundId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Play Round #$roundId')),
      body: Center(child: Text('Playing Round $roundId')),
    );
  }
}
