import 'package:flutter/material.dart';

String getProfilePictureUrl(String username) {
  return 'http://awesom-o.org:8000/getProfilePicture/$username';
}

Widget profilePictureWidget(String username, {double size = 100}) {
  final url = getProfilePictureUrl(username);

  return ClipOval(
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Show a placeholder image if loading fails
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[600]),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
    ),
  );
}
