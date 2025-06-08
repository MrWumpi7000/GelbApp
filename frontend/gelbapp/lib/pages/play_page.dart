import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PlayPage extends StatefulWidget {
  final int roundId;
  final bool flag;

  const PlayPage({required this.roundId, required this.flag, Key? key}) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool _isDropdownOpen = false; // Add this to your state
  String? _selectedPlayer;
  Map<String, dynamic>? fetchedScores;
  Future<void> _scores() async {
    final authService = AuthService();
    final scores = await authService.fetchRoundScores(widget.roundId);
    print(scores);
    setState(() {
      fetchedScores = scores;
    });
  }

  Future<void> _changeScores(int roundPlayerId) async {
    final authService = AuthService();
    await authService.changeScores(
      roundId: widget.roundId,
      roundPlayerId: roundPlayerId,
    );
    await _scores();
  }

  @override
  void initState() {
    super.initState();
    _scores();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: fetchedScores == null
        ? Center(child: CircularProgressIndicator())
        : widget.flag == false
            ? falsePlayPage()
            : truePlayPage(), // replace with your "flag == true" page
  );
}

  Scaffold falsePlayPage() {
    final players = fetchedScores?['scores'] ?? [];
    
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 8,
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    children: [
                      Text("Lobby Name: ${fetchedScores!['round_name']}", style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(height: 20),
                      Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10), // match container radius
                        child: Table(
                          border: TableBorder.all(color: Colors.white),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey[800]),
                              children: [
                                Padding(padding: const EdgeInsets.all(8.0), child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                Padding(padding: const EdgeInsets.all(8.0), child: Text('Points', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            for (var i in fetchedScores!['scores'] ?? [])
                              TableRow(children: [
                                Padding(padding: const EdgeInsets.all(8.0), child: Text(i['name'].toString(), style: TextStyle(color: Colors.white))),
                                Padding(padding: const EdgeInsets.all(8.0), child: Text(i['points'].toString(), style: TextStyle(color: Colors.white))),
                              ]),
                          ],
                        ),
                      ),
                      ),
                      SizedBox(height: 20),
                      Text("Fields yelled at: ${fetchedScores!["field_count"]}", style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 20),
                      Container(
                        width: 300, // Set width of the dropdown
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white),
                        ),
                        child: DropdownButton2<String>(
                        value: _selectedPlayer,
                        isExpanded: true,
                        iconStyleData: IconStyleData(
                          icon: _isDropdownOpen
                              ? Icon(Icons.arrow_drop_up, color: Colors.white)
                              : Icon(Icons.arrow_drop_down, color: Colors.white),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        hint: Text("Select a player", style: TextStyle(color: Colors.white)),
                        underline: SizedBox(),
                        onMenuStateChange: (isOpen) {
                          setState(() {
                            _isDropdownOpen = isOpen;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedPlayer = value;
                          });
                        },
                        items: players.map<DropdownMenuItem<String>>((player) {
                          return DropdownMenuItem<String>(
                            value: player['name'],
                            child: Text(player['name'], style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                      ),
                        ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _selectedPlayer != null ? () {
                        final player = (fetchedScores!['scores'] as List<dynamic>)
                            .firstWhere((p) => p['name'] == _selectedPlayer);
                        _changeScores(player['player_id']);
                        } : null,
                          style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(211, 254, 221, 55),
                      ),
                        child: Text("Give point", style: TextStyle(color: Colors.white)),
                      ),

                    ],
                  ),
              ),
            ),
          ),
        ),
  );
  }
}

Scaffold truePlayPage() {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 8,
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                      Text("Lobby Name:doffdggdgdd", style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(height: 20),
                      Table(
                        border: TableBorder.all(color: Colors.white),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[800]),
                            children: [
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Points', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Player ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text("Fields yelled esrdtfzgu", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ]),
              ),
            ),
          ),
        ),
  );
  }
