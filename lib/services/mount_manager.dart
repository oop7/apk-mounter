import 'package:device_apps/device_apps.dart';
import 'package:apk_mounter/services/root_api.dart';
import 'package:apk_mounter/models/mounted_app.dart';

/// Service to manage APK mounting operations
class MountManager {
  final RootAPI _rootAPI = RootAPI();

  /// Request root access from the user
  Future<bool> requestRootAccess() async {
    return await _rootAPI.hasRootPermissions();
  }

  /// Check if device has root access
  Future<bool> hasRootAccess() async {
    return await _rootAPI.hasRootPermissions();
  }

  /// Get list of all mounted apps with their details
  Future<List<MountedApp>> getMountedApps() async {
    final List<MountedApp> mountedApps = [];
    final bool hasRoot = await _rootAPI.hasRootPermissions();

    if (hasRoot) {
      final List<String> packageNames = await _rootAPI.getInstalledApps();

      for (final String packageName in packageNames) {
        final ApplicationWithIcon? app =
            await DeviceApps.getApp(packageName, true) as ApplicationWithIcon?;

        if (app != null) {
          mountedApps.add(
            MountedApp(
              packageName: app.packageName,
              appName: app.appName,
              versionName: app.versionName ?? 'Unknown',
              icon: app.icon,
            ),
          );
        }
      }
    }

    return mountedApps;
  }

  /// Mount an APK file for a specific package
  Future<bool> mountAPK(String packageName, String apkPath) async {
    try {
      return await _rootAPI.install(packageName, '', apkPath);
    } catch (e) {
      print('Error mounting APK: $e');
      return false;
    }
  }

  /// Unmount an app
  Future<void> unmountApp(String packageName) async {
    await _rootAPI.uninstall(packageName);
  }

  /// Remount an app (re-run the mount script)
  Future<bool> remountApp(String packageName) async {
    try {
      await _rootAPI.runMountScript(packageName);
      return true;
    } catch (e) {
      print('Error remounting app: $e');
      return false;
    }
  }

  /// Check if a specific app is mounted
  Future<bool> isAppMounted(String packageName) async {
    return await _rootAPI.isAppInstalled(packageName);
  }
}
