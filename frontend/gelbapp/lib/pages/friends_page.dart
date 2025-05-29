import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/friend_request_polling_service.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();

  FriendRequestPollingService? _pollingService;
  StreamSubscription? _pollingSubscription;

  List<Map<String, dynamic>> _friendsList = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];


  List<Map<String, dynamic>> _searchResults = [];

  bool _isSearching = false;
  bool _isLoading = false;
  Set<String> _sentRequests = {};

  bool _isLoadingFriends = true;
  bool _isExpanded = true;

  // Friend request related states
  bool _mailPanelOpen = false;

  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });

    _fetchFriendsList();

    _pollingService = FriendRequestPollingService();
    _pollingService!.startPolling();
    _pollingSubscription = _pollingService!.stream.listen((data) {
      setState(() {
        _friendsList = data['friendlist'] ?? [];
        _incomingRequests = data['incoming'] ?? [];
        _outgoingRequests = data['outgoing'] ?? [];
      });
    });
  }

  Future<void> _fetchFriendsList() async {
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final friends = await authService.getFriendsList();
      setState(() {
        _friendsList = friends;
      });
    } catch (e) {
      print("Error fetching friends list: $e");
    } finally {
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _fetchFriendRequests() async {

    try {
      final incoming = await authService.getIncomingFriendRequests();
      final outgoing = await authService.getOutgoingFriendRequests();

      setState(() {
        _incomingRequests = incoming;
        _outgoingRequests = outgoing;
      });
    } catch (e) {
      print('Error fetching friend requests: $e');
    }
  }

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _sentRequests = {};
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await authService.searchUsers(query);
      final filtered = results.where((user) => user['status'] == 'none' || user['status'] == 'rejected').toList();
      setState(() {
        _searchResults = filtered;
      });
    } catch (e) {
      print("Search error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(int requestId) async {
    try {
      await authService.acceptFriendRequest(requestId);
      setState(() {
        _incomingRequests.removeWhere((r) => r['request_id'] == requestId);
      });
      _fetchFriendsList();
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await authService.rejectFriendRequest(requestId);
      setState(() {
        _incomingRequests.removeWhere((r) => r['request_id'] == requestId);
      });
      _fetchFriendRequests();
    } catch (e) {
      print('Error rejecting friend request: $e');
    }
  }

  Future<void> _cancelOutgoingRequest(int requestId) async {
    try {
      await authService.cancelFriendRequest(requestId);
      setState(() {
        _outgoingRequests.removeWhere((r) => r['request_id'] == requestId);
      });
      // For now, just print a message

    } catch (e) {
      print('Error canceling outgoing friend request: $e');
    }
  }

@override
void dispose() {
  _pollingSubscription?.cancel();
  _pollingService?.stopPolling();
  _searchController.dispose();
  super.dispose();
}


  Widget _buildMailRequestsView() {
    return Column(
      children: [
        // Top bar with back icon and title
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _mailPanelOpen = false;
                  });
                },
              ),
              SizedBox(width: 8),
              Text(
                'Inbox',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ExpansionTile(
                  initiallyExpanded: true,
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  title: Text(
                    'Incoming Friend Requests (${_incomingRequests.length})',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  leading: Icon(Icons.person_add, color: Colors.white),
                  children: _incomingRequests.isEmpty
                      ? [
                          ListTile(
                            title: Text('No incoming requests', style: TextStyle(color: Colors.white54)),
                          )
                        ]
                      : _incomingRequests.map((request) {
                          final username = request['username'] ?? '';
                          final request_id = request['request_id'] ?? '';
                          return ListTile(
                            title: Text(username, style: TextStyle(color: Colors.white)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _acceptRequest(request_id),
                                  tooltip: 'Accept',
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _rejectRequest(request_id),
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
                ExpansionTile(
                  initiallyExpanded: false,
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  title: Text(
                    'Outgoing Friend Requests (${_outgoingRequests.length})',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  leading: Icon(Icons.send, color: Colors.white),
                  children: _outgoingRequests.isEmpty
                      ? [
                          ListTile(
                            title: Text('No outgoing requests', style: TextStyle(color: Colors.white54)),
                          )
                        ]
                      : _outgoingRequests.map((request) {
                          final username = request['username'] ?? '';
                          final request_id = request['request_id'] ?? '';
                          return ListTile(
                            title: Text(username, style: TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: Icon(Icons.close, color: Colors.red), // same as reject icon
                              onPressed: () => _cancelOutgoingRequest(request_id),
                              tooltip: 'Cancel request',
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Colors.black,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 350,
                height: 600, // fix height for Expanded usage inside
                child: _mailPanelOpen
                    ? _buildMailRequestsView()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearch,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    hintText: "Search for new friends...",
                                    prefixIcon: Icon(Icons.search),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _isSearching = false;
                                                _searchResults.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _mailPanelOpen = true;
                                      });
                                    },
                                    icon: Icon(Icons.mail, color: Colors.white),
                                  ),
                                  if (_incomingRequests.isNotEmpty)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _isSearching
                              ? _isLoading
                                  ? CircularProgressIndicator()
                                  : _searchResults.isEmpty
                                      ? Text("No users found.", style: TextStyle(color: Colors.white))
                                      : Expanded(
                                          child: ListView.builder(
                                            itemCount: _searchResults.length,
                                            itemBuilder: (context, index) {
                                              final user = _searchResults[index];
                                              final username = user['username'] ?? '';

                                              return ListTile(
                                                title: Text(
                                                  username,
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                trailing: ElevatedButton(
                                                  onPressed: _sentRequests.contains(username)
                                                      ? null
                                                      : () async {
                                                          try {
                                                            await authService.sendFriendRequest(username);
                                                            _fetchFriendRequests();
                                                            setState(() {
                                                              _sentRequests.add(username);
                                                            });
                                                          } catch (e) {
                                                            print("Send request error: $e");
                                                          }
                                                        },
                                                  child: Text(_sentRequests.contains(username) ? "Sent" : "Add"),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                              : _isLoadingFriends
                                  ? CircularProgressIndicator()
                                  : Expanded(
                                      child: ListView(
                                        children: [
                                          ExpansionTile(
                                            initiallyExpanded: _isExpanded,
                                            onExpansionChanged: (val) => setState(() => _isExpanded = val),
                                            iconColor: Colors.white,
                                            collapsedIconColor: Colors.white,
                                            title: Text(
                                              'Your Friends (${_friendsList.length})',
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            leading: Icon(
                                              _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                              color: Colors.white,
                                            ),
                                            children: _friendsList.isEmpty
                                                ? [
                                                    ListTile(
                                                      title: Text('No friends found.', style: TextStyle(color: Colors.white54)),
                                                    )
                                                  ]
                                                : _friendsList.map((friend) {
                                                    final username = friend['username'] ?? '';
                                                    return ListTile(
                                                      title: Text(username, style: TextStyle(color: Colors.white)),
                                                      trailing: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(Icons.remove, color: Colors.red),
                                                            onPressed: () async {
                                                              await authService.removeFriend(friend['id']);
                                                              _fetchFriendsList();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                          ),
                                        ],
                                      ),
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
