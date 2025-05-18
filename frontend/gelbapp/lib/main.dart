import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'pages/create_lobby_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GelbApp',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFEDD37),
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: _getRoute,
    );
  }

  Route<dynamic>? _getRoute(RouteSettings settings) {
    switch (settings.name) {
      // Routes without animation:
      case '/':
        return _noAnimationRoute(HomePage(), settings);
      case '/leaderboard':
        return _noAnimationRoute(LeaderboardPage(), settings);
      case '/statistics':
        return _noAnimationRoute(StatisticsPage(), settings);
      case '/profile':
        return _noAnimationRoute(ProfilePage(), settings);

      // Routes with default animation:
      case '/create_lobby':
        return MaterialPageRoute(
          builder: (_) => CreateLobbyPage(),
          settings: settings,
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginPage(),
          settings: settings,
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => RegisterPage(),
          settings: settings,
        );
      default:
        return null;
    }
  }

  PageRoute _noAnimationRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
