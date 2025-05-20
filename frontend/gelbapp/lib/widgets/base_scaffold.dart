import 'package:flutter/material.dart';
import 'custom_bottom_app_bar.dart';

class BaseScaffold extends StatelessWidget {

  final GlobalKey<CustomBottomAppBarState>? bottomBarKey;
  final int currentIndex;
  final Widget child;

  const BaseScaffold({required this.child, required this.currentIndex, this.bottomBarKey, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFFEDD37),
      body: child,
      bottomNavigationBar: CustomBottomAppBar(
      key: bottomBarKey, // <-- This connects the key!
      currentIndex: currentIndex,
    ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/create_lobby');
        },
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add, size: 30, color: Colors.black),
        ),
      ),
    );
  }
}
