import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http_parser/http_parser.dart';

class AuthService {
  final String _baseUrl = 'http://awesom-o.org:8000';

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username_or_email': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> whoAmI() async {
    final url = Uri.parse('$_baseUrl/whoami');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'token': await getToken(),
      }),
    );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final username = data['username'];
    final email = data['email'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);

    return true;
  } else {
    return false;
  }
}

  Future<ImageProvider> getProfilePictureBytes() async {
  final prefs = await SharedPreferences.getInstance();
  final url = Uri.parse('$_baseUrl/profile_picture');

  final cachedImageBase64 = prefs.getString('image');
  if (cachedImageBase64 != null) {
    final bytes = base64Decode(cachedImageBase64);
    return MemoryImage(bytes);
  }

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: '{"token": "${await getToken()}"}',
  );

  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    final encoded = base64Encode(bytes);
    await prefs.setString('image', encoded); // store as string
    return MemoryImage(bytes);
  } else {
    throw Exception('Failed to load profile picture');
  }
}

  Future<void> uploadProfilePictureMobile(io.File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('image');
    final url = Uri.parse('$_baseUrl/upload_profile_picture');
    final token = await getToken();
    if (token == null) throw Exception('Token is null');

    final request = http.MultipartRequest('POST', url)
      ..fields['token'] = token
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'png'),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('image'); 
      await getProfilePictureBytes();
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to upload profile picture');
    }
  }

  // Web version
  Future<void> uploadProfilePictureWeb(Uint8List bytes, String filename) async {
    final url = Uri.parse('$_baseUrl/upload_profile_picture');
    final token = await getToken();
    if (token == null) throw Exception('Token is null');

    final request = http.MultipartRequest('POST', url)
      ..fields['token'] = token
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'png'),
      ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('image'); 
      await getProfilePictureBytes();
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to upload profile picture');
    }
  }

 Future<List<Map<String, dynamic>>> searchUsers(String query) async {
  final url = Uri.parse('$_baseUrl/search_users');
  final token = await getToken(); // your token fetch logic

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'token': token,
      'query': query,
    }),
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Invalid response format');
    }
  } else {
    throw Exception('Failed to search users: ${response.statusCode}');
  }
}

Future<String> sendFriendRequest(String friendUsername) async {
  final url = Uri.parse('$_baseUrl/add_friend');

  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'friend_username': friendUsername,
      'token': token,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'] ?? 'Friend request sent.';
  } else {
    throw Exception(
      'Failed to send friend request: ${response.statusCode}\n${response.body}',
    );
  }
}

Future<List<Map<String, dynamic>>> getFriendsList() async {
  final url = Uri.parse('$_baseUrl/friends');

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': await getToken()}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['friends']);
  } else {
    throw Exception('Failed to load friends: ${response.statusCode}');
  }
}

Future<List<Map<String, dynamic>>> getOutgoingFriendRequests() async {
  final url = Uri.parse('$_baseUrl/friend_requests/outgoing');
  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final requests = data['outgoing_requests'];
    return List<Map<String, dynamic>>.from(requests);
  } else {
    throw Exception(
      'Failed to load outgoing friend requests: ${response.statusCode}\n${response.body}',
    );
  }
}

Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
  final url = Uri.parse('$_baseUrl/friend_requests/incoming');
  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final requests = data['incoming_requests'];
    return List<Map<String, dynamic>>.from(requests);
  } else {
    throw Exception(
      'Failed to load incoming friend requests: ${response.statusCode}\n${response.body}',
    );
  }
}

Future<bool> acceptFriendRequest(int requestId) async {
  final url = Uri.parse('$_baseUrl/accept_friend?request_id=$requestId');
  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(
      'Failed to accept friend request: ${response.statusCode}\n${response.body}',
    );
  }
}

Future<bool> rejectFriendRequest(int requestId) async {
  final url = Uri.parse('$_baseUrl/reject_friend?request_id=$requestId');
  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(
      'Failed to reject friend request: ${response.statusCode}\n${response.body}',
    );
  }
}

Future<bool> cancelFriendRequest(int requestId) async {
  final url = Uri.parse('$_baseUrl/cancel_friend_request?request_id=$requestId');
  final token = await getToken();

  final response = await http.post(
    url,
    headers: {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception(
      'Failed to cancel friend request: ${response.statusCode}\n${response.body}',
    );
  }
}
Future<bool> removeFriend(int friendUserId) async {
  final url = Uri.parse('$_baseUrl/remove_friend/$friendUserId');
  final token = await getToken();

  final request = http.Request('DELETE', url)
    ..headers.addAll({
      'accept': 'application/json',
      'Content-Type': 'application/json',
    })
    ..body = jsonEncode({'token': token});

  final response = await request.send();

  if (response.statusCode == 200) {
    return true;
  } else {
    final responseBody = await response.stream.bytesToString();
    throw Exception('Failed to remove friend: ${response.statusCode}\n$responseBody');
  }
}

  Future<bool> refreshUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/whoami');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('username', data['username']);
      await prefs.setString('email', data['email']);
      return true;
    } else {
      return false;
    }
  }

  Future<void> createRound({
  required String name,
  required List<Map<String, dynamic>> players,
}) async {
  final token = await getToken();
  final url = Uri.parse('$_baseUrl/rounds/create');

  final body = jsonEncode({
    'name': name,
    'token': token,
    'players': players,
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    print('Round Created Successfully: ${response.body}');
  } else {
    throw Exception('Failed to create round: ${response.statusCode}');
  }
}

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

Future<Map<String, String>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString('username');
  String? email = prefs.getString('email');

  if (username == null || email == null) {
    await AuthService().whoAmI();

    username = prefs.getString('username');
    email = prefs.getString('email');
  }

  return {
    'username': username ?? '',
    'email': email ?? '',
  };
}


