import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:gelbapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String sanitizeVersion(String version) {
  // Remove build metadata like "+7", keep pre-release like "-alpha"
  return version.split('+').first;
}

Future<void> checkForUpdateAndShow() async {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version.split('+').first);
    final isCurrentPre = currentVersion.isPreRelease;

    final prefs = await SharedPreferences.getInstance();
    final isBetaTester = prefs.getBool('isBetaTester') ??
        await AuthService().isBetaTester();

    final releaseMap = await AuthService().getLatestGitHubReleasePair();

    final stableRelease = releaseMap['latestStable'];
    final preRelease = releaseMap['latestPre'];

    Version? latestVersion;
    Map<String, dynamic>? latestRelease;

    if (isBetaTester && preRelease != null) {
      final preVer = Version.parse((preRelease['tag_name'] as String).replaceFirst('v', '').split('+').first);
      latestVersion = preVer;
      latestRelease = preRelease;
    }

    if (stableRelease != null) {
      final stableVer = Version.parse((stableRelease['tag_name'] as String).replaceFirst('v', '').split('+').first);
      if (latestVersion == null || stableVer > latestVersion) {
        latestVersion = stableVer;
        latestRelease = stableRelease;
      }
    }

    if (latestVersion != null && latestVersion > currentVersion && latestRelease != null) {
      final assetList = latestRelease['assets'] as List<dynamic>;
      print(assetList.last['browser_download_url'].toString());
      final assetUrl = assetList.isNotEmpty
          ? assetList.first['browser_download_url'].toString()
          : null;

      if (assetUrl != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Update Available"),
            content: Text(
              "New version ${latestRelease?['tag_name']} is available. "
              "You have ${packageInfo.version}.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(assetUrl);
                  if (!kIsWeb && Platform.isAndroid && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  Navigator.of(context).pop();
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
    }
  } catch (e) {
    debugPrint("Version check failed: $e");
  }
}
