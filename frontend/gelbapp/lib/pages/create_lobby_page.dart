import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PlayerInput {
  final int? userId;
  final String? guestName;

  PlayerInput({this.userId, this.guestName});

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'guest_name': guestName,
      };
}

class CreateLobbyPage extends StatefulWidget {
  @override
  _CreateLobbyPageState createState() => _CreateLobbyPageState();
}

class _CreateLobbyPageState extends State<CreateLobbyPage> {
  bool flag = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _guestController = TextEditingController();
  Map<String, dynamic>? _selectedFriend;
  final List<PlayerInput> _players = [];
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>>? _friends;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await AuthService().getFriendsList();
    setState(() {
      _friends = friends;
    });
  }

  void _addFriend() {
    if (_selectedFriend != null &&
        !_players.any((p) => p.userId == _selectedFriend!['id'])) {
      setState(() {
        _players.add(PlayerInput(userId: _selectedFriend!['id']));
        _selectedFriend = null;
        FocusScope.of(context).unfocus();
      });
    }
  }


  void _addGuest() {
    final name = _guestController.text.trim();
    if (name.isNotEmpty &&
        !_players.any((p) => p.guestName?.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _players.add(PlayerInput(guestName: name));
        _guestController.clear();
        FocusScope.of(context).unfocus();
      });
    }
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
  }

void _createLobby() async {
  if (!_formKey.currentState!.validate()) return;

  final response = await AuthService().createRound(
    name: _nameController.text.trim(),
    players: _players.map((p) => p.toJson()).toList(),
  );

  if (response.containsKey('error')) {
    // Show error if response has an 'error' key
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error']),
        backgroundColor: Colors.red,
      ),
    );
  } else if (response.containsKey('round_id')) {
    final roundId = response['round_id'];

    // Navigate to the play page with the round id
    Navigator.pushReplacementNamed(context, '/play/$roundId/$flag');
  } else {
    // Fallback in case of unexpected response
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unexpected error occurred.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: Text('Create Lobby', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 8,
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 350,
                height: 650,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Lobby Name',
                            labelStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          cursorColor: Color(0xFFFEDD37),
                          controller: _nameController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a lobby name'
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Microphone Enabled',
                              style: TextStyle(color: Colors.white, fontSize: 15)),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(activeColor: Color(0xFFFEDD37), value: flag, onChanged: null),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedFriend,
                            isExpanded: true,
                            dropdownColor: Colors.black87,
                            decoration: InputDecoration(
                              labelText: "Select Friend",
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white,
                            hint: Text("Friends...", style: TextStyle(color: Colors.white70)),
                            items: _friends
                                ?.where((friend) =>
                                    !_players.any((p) => p.userId == friend['id']))
                                .map((friend) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: friend,
                                child: Text(
                                  friend['username'] ?? friend['name'] ?? 'Unknown',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFriend = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.white),
                          onPressed: _addFriend,
                          tooltip: 'Add Friend',
                        ),
                      ],
                    ),

                      // Guest TextField
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _guestController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFFEDD37), width: 2.0),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                hintText: "Enter guest name",
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                              cursorColor: Color(0xFFFEDD37),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _addGuest,
                          ),
                        ],
                      ),
                      Divider(color: Colors.white38),
                      // Player List
                      ..._players.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;

                        return ListTile(
                          title: Text(
                            p.userId != null
                                ? "Friend ID: ${_friends?.firstWhere((f) => f['id'] == p.userId)['username'] ?? 'Unknown'}"
                                : "Guest: ${p.guestName}",
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removePlayer(index),
                          ),
                        );
                      }),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _createLobby,
                        style: ElevatedButton.styleFrom( backgroundColor: Color.fromARGB(211, 254, 221, 55),),
                        child: Text('Create', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
