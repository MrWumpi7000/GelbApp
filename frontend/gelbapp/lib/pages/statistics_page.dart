import 'package:flutter/material.dart';
import 'package:gelbapp/widgets/base_scaffold.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import "../widgets/profilePictureWidget.dart";

Future<List<LeaderboardEntry>> fetchLeaderboard() async {
  try {
    List<LeaderboardEntry>? leaderboard = await AuthService().fetchLeaderboard();
    if (leaderboard == null || leaderboard.isEmpty) {
      throw Exception('No leaderboard data found');
    }
    return leaderboard;
  } catch (e) {
    print('Error: $e');
    return [];
  }
}

Future<UserStatistics> fetchUserStatistics() async {
  try {
    UserStatistics? stats = await AuthService().fetchUserStatistics();
    if (stats == null) {
      throw Exception('User statistics not found');
    }
    print('User: ${stats.username}, Total Rounds: ${stats.totalRounds}, Total Points: ${stats.totalPoints}, Total Gelbfelder: ${stats.totalGelbfelder}, Best Score: ${stats.bestScoreInRound}');
    return stats;
  } catch (e) {
    print('Error: $e');
    return UserStatistics(
      username: '',
      totalRounds: 0,
      totalPoints: 0,
      totalGelbfelder: 0,
      bestScoreInRound: 0,
    );
  }
}

Future<List<RoundHistory>> fetchUserHistoryRounds() async {
try {
    List<RoundHistory> stats = await AuthService().fetchUserHistoryRounds();
    for (var stat in stats) {
      print('Round: ${stat.roundName}, Points: ${stat.points}, Date: ${stat.date}');
    }
    return stats;
  } catch (e) {
    print('Error: $e');
    return [];
  }
}

class StatisticsPage extends StatefulWidget {
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedTab = 0;

  final List<String> topTabs = ['Me', 'Public', 'History'];


  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 8,
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 300,
                height: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top AppBar-style Tab Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding: EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(topTabs.length, (index) {
                              final isSelected = _selectedTab == index;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedTab = index),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 250),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    topTabs[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),
                    // Divider
                    Divider(
                      color: Colors.white30,
                      thickness: 1,
                    ),
                    // Main Content Area
                    if (_selectedTab == 0)
                      Expanded(child: UserStatisticsTab())  
                    else if (_selectedTab == 1) 
                      Expanded(child: LeaderboardPage())
                    else if (_selectedTab == 2)
                      Expanded(child: HistoryTab()),
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

class HistoryTab extends StatefulWidget {
  @override
  _HistoryTabState createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoundHistory>>(
      future: fetchUserHistoryRounds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error loading statistics',
                style: TextStyle(color: Colors.red)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('No statistics found',
                style: TextStyle(color: Colors.white)));
        } else {
          final stats = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    "History of Rounds:",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              
              ),
              Divider(color: Colors.white24 , thickness: 1),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return ListTile(
                        onTap: () => print(stat),
                        title: Text('Name: ${stat.roundName}',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Points: ${stat.points}',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Date: ${DateFormat('d MMMM yyyy, HH:mm').format(stat.date.toLocal())}',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}


class UserStatisticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserStatistics>(
      future: fetchUserStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading statistics',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.username.isEmpty) {
          return Center(
            child: Text(
              'No statistics found',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          final stats = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      "Your Statistics:",
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
                Divider(color: Colors.white30, thickness: 1),
                SizedBox(height: 12),
                Text('👤 Username: ${stats.username}',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('🌀 Total Rounds: ${stats.totalRounds}',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('🏁 Total Points: ${stats.totalPoints}',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('🌾 Total Gelbfelder: ${stats.totalGelbfelder}',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('🎯 Best Score in a Round: ${stats.bestScoreInRound}',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          );
        }
      },
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: fetchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading leaderboard',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No leaderboard data',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          final leaderboard = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed title on top
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    "Leaderboard:",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              Divider(color: Colors.white24, thickness: 1),

              // Scrollable list
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: leaderboard.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.white30),
                    itemBuilder: (context, index) {
                      final entry = leaderboard[index];
                      return ListTile(
                        leading: profilePictureWidget(entry.username, size: 50),
                        title: Text("Username: ${entry.username}",
                            style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Points: ${entry.totalPoints}',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Rounds: ${entry.roundsPlayed}',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Best Round: ${entry.bestSingleRound}',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
