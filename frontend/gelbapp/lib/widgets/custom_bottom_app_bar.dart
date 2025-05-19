import 'package:flutter/material.dart';
import 'package:gelbapp/services/auth_service.dart';

class CustomBottomAppBar extends StatefulWidget {
  final int currentIndex;

  const CustomBottomAppBar({required this.currentIndex, super.key});

  @override
  State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
  late Future<ImageProvider> _userImageFuture;

  @override
  void initState() {
    super.initState();
    _userImageFuture = AuthService().getProfilePictureBytes();
  }

 void _onTap(BuildContext context, int index) {
  final routes = ['/', '/leaderboard', '/statistics', '/profile'];

  if (index < routes.length && ModalRoute.of(context)?.settings.name != routes[index]) {
    Navigator.pushNamed(context, routes[index]);
  }
}

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: BottomAppBar(
        color: Colors.black87,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, "Home", 0),
              _buildNavItem(context, Icons.group, "Leaderboard", 1),
              const SizedBox(width: 40),
              _buildNavItem(context, Icons.send, "Stats", 2),
              _buildProfileItem(context, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, int index) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<ImageProvider>(
            future: _userImageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              } else if (snapshot.hasError) {
                return const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.error, size: 14),
                );
              } else {
                return CircleAvatar(
                  radius: 12,
                  backgroundImage: snapshot.data!,
                );
              }
            },
          ),
          const SizedBox(height: 2),
          Text(
            "Profile",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
