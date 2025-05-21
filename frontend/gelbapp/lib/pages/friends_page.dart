import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';
import '../services/auth_service.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
final TextEditingController _searchController = TextEditingController();
List<Map<String, dynamic>> _searchResults = [];
bool _isSearching = false;
bool _isLoading = false;
Set<String> _sentRequests = {};

List<Map<String, dynamic>> _friendsList = [];
bool _isLoadingFriends = true;
bool _isExpanded = true;

@override
void initState() {
  super.initState();
  _searchController.addListener(() {
    setState(() {}); // rebuilds to show/hide clear icon
  });
  _fetchFriendsList();
}

  void _fetchFriendsList() async {
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final friends = await AuthService().getFriendsList();
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
      final results = await AuthService().searchUsers(query);
      // Only show users with status == "none"
      final filtered = results.where((user) => user['status'] == 'none').toList();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                child: Column(
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
                        SizedBox(width: 8), // Some spacing between TextField and IconButton
                        IconButton(
                          onPressed: () {
                            print("Mail icon tapped");
                          },
                          icon: Icon(Icons.mail, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    if (_isSearching)
                      _isLoading
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
                                      trailing: _sentRequests.contains(username)
                                          ? Icon(Icons.check, color: Colors.green)
                                          : IconButton(
                                              icon: Icon(Icons.add, color: Colors.green),
                                              onPressed: () async {
                                                try {
                                                  await AuthService().sendFriendRequest(username);
                                                  setState(() {
                                                    _sentRequests.add(username);
                                                  });
                                                  print('Friend request sent to: $username');
                                                  print(user);
                                                } catch (e) {
                                                  print('Failed to send friend request: $e');
                                                }
                                              },
                                            ),
                                    );
                                  }
                                  ),
                                )
                    else
                      Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_friendsList.length, (index) {
                      final friend = _friendsList[index];
                      return ExpansionTile(
                        initiallyExpanded: _isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isExpanded = expanded;
                          });
                        },
                        title: Text(
                          "Friends: ${_friendsList.length}",
                          style: TextStyle(color: Colors.white),
                        ),
                        leading: Icon(Icons.people, color: Colors.white),
                        trailing: Icon(
                          _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        children: _friendsList.map((friend) {
                          return ListTile(
                            title: Text(friend['username'] ?? '', style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                      );

                    }),
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
