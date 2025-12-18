import 'dart:typed_data';

/// Model representing a mounted application
class MountedApp {
  final String packageName;
  final String appName;
  final String versionName;
  final Uint8List icon;

  MountedApp({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.icon,
  });

  @override
  String toString() {
    return 'MountedApp{packageName: $packageName, appName: $appName, version: $versionName}';
  }
}
