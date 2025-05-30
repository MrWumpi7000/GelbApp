import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 0,
      child: Center(
        child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  color: const Color.fromARGB(255, 15, 15, 14),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: 300,
                      child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GelbApp',
                                style: TextStyle(fontSize: 24, color: Colors.white),
                              ),
                              Image.asset(
                                'assets/logo.png',
                                width: 50,
                                height: 50,
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          Text(
                            'How to Play GelbApp',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'GelbApp is a fun family game for car rides! The goal is simple: '
                            'spot yellow rapeseed fields and be the first to shout "Gelb!" '
                            'Whoever says it first gets 1 point!',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'How the App Works:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '• The app helps you track points while driving.\n'
                            '• AI image recognition might be added in the future, but for now it’s manual.\n'
                            '• Tap "Create" to start a new round.\n'
                            '• Add friends (from your Friends page) to include them in the round.\n'
                            '• You can also add guests—points from guests are not saved in public stats.\n'
                            '• Check out the Statistics page to see top players and scores.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Have fun shouting "Gelb!" and enjoy the ride!',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
      ),
    );
  }
}
