import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';
import 'package:gelbapp/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, String>> _userDataFuture;
  late Future<ImageProvider> _userImageFuture;

  @override
  void initState() {
    super.initState();
    _userImageFuture = AuthService().getProfilePictureBytes(); // returns Future<ImageProvider>
    _userDataFuture = getUserData(); // also a Future
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      child: FutureBuilder<Map<String, String>>(
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          } else {
            final data = userSnapshot.data!;
            return Center(
              child: Card(
                color: const Color.fromARGB(255, 15, 15, 14),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<ImageProvider>(
                      future: _userImageFuture,
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        } else {
                          return CircleAvatar(
                            radius: 50,
                            backgroundImage: imageSnapshot.data!,
                          );
                        }
                      },
                    ),
                      const SizedBox(height: 20),
                      const Text('GelbApp', style: TextStyle(fontSize: 24, color: Colors.white)),
                      const SizedBox(height: 30),
                      Text('Username: ${data['username']}', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      Text('Email: ${data['email']}', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          AuthService().logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
