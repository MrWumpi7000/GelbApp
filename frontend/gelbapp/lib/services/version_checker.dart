import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:gelbapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> checkForUpdateAndShow() async {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final authService = AuthService();
    final prefs = await SharedPreferences.getInstance();
    // Use setting or user preference to decide:
    final isBetaTester = prefs.getBool('isBetaTester') ?? await authService.isBetaTester();

    final release = await authService.getLatestGitHubRelease(
      includePreRelease: isBetaTester,
    );

    final latest = release['tag_name'].toString().replaceFirst('v', '');

    var githubReleasesUrl = release['assets'][0]['browser_download_url'].toString();

    if (Version.parse(latest) > Version.parse(currentVersion)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Update Available"),
          content: Text("New version $latest available. You have $currentVersion."),
          actions: [
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(githubReleasesUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Update"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Later"),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    debugPrint("Version check failed: $e");
  }
}
