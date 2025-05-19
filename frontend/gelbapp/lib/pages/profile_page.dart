import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';
import 'package:gelbapp/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:gelbapp/widgets/custom_bottom_app_bar.dart';
import 'dart:io' as io;

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, String>> _userDataFuture;
  late Future<ImageProvider> _userImageFuture;
  final GlobalKey<CustomBottomAppBarState> _bottomBarKey = GlobalKey<CustomBottomAppBarState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _userImageFuture = AuthService().getProfilePictureBytes();
    _userDataFuture = getUserData();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await AuthService().uploadProfilePictureWeb(bytes, pickedFile.name);
        } else {
          final file = io.File(pickedFile.path);
          await AuthService().uploadProfilePictureMobile(file);
        }

        // Reload image after upload
        setState(() {
          _bottomBarKey.currentState?.refreshProfileImage();
          _userImageFuture = AuthService().getProfilePictureBytes();
        });
      } catch (e) {
        print('Upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      bottomBarKey: _bottomBarKey,
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
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: FutureBuilder<ImageProvider>(
                          future: _userImageFuture,
                          builder: (context, imageSnapshot) {
                            if (imageSnapshot.connectionState == ConnectionState.waiting) {
                              return const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            } else if (imageSnapshot.hasData) {
                              return CircleAvatar(
                                radius: 50,
                                backgroundImage: imageSnapshot.data,
                              );
                            } else {
                              return const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person),
                              );
                            }
                          },
                        ),
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
