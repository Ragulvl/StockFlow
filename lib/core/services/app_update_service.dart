import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final DateTime lastChecked;

  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.lastChecked,
  });
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _kCurrentVersion = '1.0.0+1';
  static const String _kLastCheckKey = 'last_app_update_check';

  // Remote Version Manifest URL (e.g. GitHub Releases / Firebase / Free HTTPS Endpoint)
  // When you release a new app build in Coimbatore, update version.json at this endpoint!
  static const String updateManifestUrl = 'https://raw.githubusercontent.com/ragul-stockflow/updates/main/version.json';

  Future<AppUpdateInfo> checkForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastCheckKey, DateTime.now().toIso8601String());

    try {
      final response = await http.get(Uri.parse(updateManifestUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String? ?? _kCurrentVersion;
        final downloadUrl = data['url'] as String? ?? '';
        final notes = data['notes'] as String? ?? 'Performance improvements and bug fixes.';
        final force = data['force_update'] as bool? ?? false;

        final isAvailable = _compareVersions(latestVersion, _kCurrentVersion) > 0;

        return AppUpdateInfo(
          currentVersion: _kCurrentVersion,
          latestVersion: latestVersion,
          isUpdateAvailable: isAvailable,
          downloadUrl: downloadUrl,
          releaseNotes: notes,
          forceUpdate: force,
          lastChecked: DateTime.now(),
        );
      }
    } catch (_) {
      // Offline fallback / default status
    }

    return AppUpdateInfo(
      currentVersion: _kCurrentVersion,
      latestVersion: _kCurrentVersion,
      isUpdateAvailable: false,
      downloadUrl: '',
      releaseNotes: 'Your app is up to date.',
      forceUpdate: false,
      lastChecked: DateTime.now(),
    );
  }

  int _compareVersions(String v1, String v2) {
    try {
      final cleanV1 = v1.split('+').first;
      final cleanV2 = v2.split('+').first;
      final parts1 = cleanV1.split('.').map(int.parse).toList();
      final parts2 = cleanV2.split('.').map(int.parse).toList();

      for (int i = 0; i < parts1.length && i < parts2.length; i++) {
        if (parts1[i] > parts2[i]) return 1;
        if (parts1[i] < parts2[i]) return -1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Downloads the APK over-the-air (OTA) wirelessly and triggers Android Package Installation
  Future<File?> downloadApk(String url, Function(double progress) onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/stockflow_update.apk');
      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(downloadedBytes / totalBytes);
        }
      });

      await sink.close();
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<bool> installDownloadedApk(File apkFile) async {
    try {
      const channel = MethodChannel('com.stockflow.stockflow/app_update');
      final bool success = await channel.invokeMethod('installApkFile', {'path': apkFile.path});
      return success;
    } catch (e) {
      return false;
    }
  }
}
