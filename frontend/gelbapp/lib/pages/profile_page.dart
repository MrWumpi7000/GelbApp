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
    _bottomBarKey.currentState?.refreshProfileImage();
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

  Widget _buildProfileAvatar() {
    return FutureBuilder<ImageProvider>(
      future: _userImageFuture,
      builder: (context, imageSnapshot) {
        Widget avatar;

        if (imageSnapshot.connectionState == ConnectionState.waiting) {
          avatar = const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (imageSnapshot.hasData) {
          avatar = CircleAvatar(
            radius: 50,
            backgroundImage: imageSnapshot.data,
          );
        } else {
          avatar = const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 40),
          );
        }

        return GestureDetector(
          onTap: () {
            if (imageSnapshot.hasData) {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageSnapshot.data!,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ),
                ),
              );
            } else {
              _pickAndUploadImage();
            }
          },
          child: Stack(
            children: [
              avatar,
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                color: const Color.fromARGB(255, 15, 15, 14),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(height: 20),
                        const Text('GelbApp', style: TextStyle(fontSize: 24, color: Colors.white)),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Username:', style: TextStyle(color: Colors.white)),
                            Text(data['username'] ?? '', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('E-mail:', style: TextStyle(color: Colors.white)),
                            Text(data['email'] ?? '', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Divider(
                              color: Colors.grey[400],
                              thickness: 1,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/settings');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.settings, color: Colors.white),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Settings',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              color: Colors.grey[400],
                              thickness: 1,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  AuthService().logout();
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.logout, color: Colors.white),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
