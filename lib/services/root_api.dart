import 'package:flutter/foundation.dart';
import 'package:root/root.dart';

class RootAPI {
  final String _modulesDirPath = '/data/adb/modules';

  static const String _serviceShTemplate = r'''#!/system/bin/sh
package_name="__PKG_NAME__"
version="__VERSION__"

# Resolve the module directory
module_dir="$(dirname "$0")"
if [ "${module_dir#"/"}" = "$module_dir" ] && command -v readlink >/dev/null 2>&1; then
  module_dir="$(dirname "$(readlink -f "$0")")"
fi
if [ "${module_dir#"/"}" = "$module_dir" ]; then
  module_dir="/data/adb/modules/${package_name}-mounter"
fi

base_dir="$module_dir"
mkdir -p "$module_dir"

log="$module_dir/log.txt"
rm -f "$log"
exec >> "$log" 2>&1

base_path="$base_dir/$package_name.apk"

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 3; done
until [ -d "/sdcard/Android" ]; do sleep 1; done

grep "$package_name" /proc/mounts | while read -r line; do
  echo "$line" | cut -d " " -f 2 | sed "s/apk.*/apk/" | xargs -r umount -l
done

waited=0
max_wait=180
stock_path=""
stock_versions=""
while [ "$waited" -lt "$max_wait" ]; do
  stock_path_data="$(pm path "$package_name" | grep base | grep /data/app/ | head -n 1 | sed 's/package://g')"
  stock_path_fallback="$(pm path "$package_name" | grep base | head -n 1 | sed 's/package://g')"
  if [ -z "$stock_path_data" ] && [ -z "$stock_path_fallback" ]; then
    stock_path_cmd="$(cmd package path "$package_name" 2>/dev/null | grep base | head -n 1 | sed 's/package://g')"
  else
    stock_path_cmd=""
  fi
  stock_path="${stock_path_data:-${stock_path_fallback:-$stock_path_cmd}}"

  stock_versions="$(dumpsys package "$package_name" | awk -v pkg="$package_name" '
    $0 ~ ("Package \\[" pkg "\\]") { in_pkg = 1 }
    $0 ~ /Hidden system package/ { in_pkg = 0 }
    in_pkg && /versionName=/ { sub(/.*versionName=/, ""); print }
  ' | tr -d '\r')"

  if [ -n "$stock_versions" ] && [ -z "$stock_path" ]; then
    stock_path="$(pm path "$package_name" | grep base | head -n 1 | sed 's/package://g')"
    if [ -z "$stock_path" ]; then
      stock_path="$(cmd package path "$package_name" 2>/dev/null | grep base | head -n 1 | sed 's/package://g')"
    fi
  fi

  if [ -n "$stock_path" ] && [ -f "$stock_path" ] && [ -n "$stock_versions" ]; then
    break
  fi
  waited=$((waited + 1))
  sleep 1
done

echo "base_path: $base_path"
echo "stock_path: $stock_path"
echo "base_version: $version"
echo "stock_versions: $(echo "$stock_versions" | tr '\n' ' ' | xargs)"

if ! echo "$stock_versions" | grep -Fxq "$version"; then
  echo "Not mounting as versions don't match"
  exit 1
fi

if [ -z "$stock_path" ] || [ -z "$stock_versions" ]; then
  echo "Not mounting as app info could not be loaded"
  exit 1
fi

if [ ! -f "$base_path" ]; then
  echo "Not mounting as patched APK is missing: $base_path"
  exit 1
fi

chcon u:object_r:apk_data_file:s0 "$base_path"
mount -o bind "$base_path" "$stock_path"
''';

  static const String _modulePropTemplate = r'''id=__PKG_NAME__-mounter
name=__LABEL__ Mounter
version=__VERSION__
versionCode=0
author=APK Mounter
description=Mounts the patched APK on top of the original one (Implementation inspired by Morphe Manager)
''';


  Future<bool> isRooted() async {
    try {
      final bool? isRooted = await Root.isRootAvailable();
      if (isRooted != null && isRooted) return true;
      final String? result = await Root.exec(cmd: 'id');
      return result != null && (result.contains('uid=0') || result.contains('root'));
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<bool> hasRootPermissions() async {
    try {
      bool? isRooted = await Root.isRootAvailable();
      if (isRooted != null && isRooted) {
        isRooted = await Root.isRooted();
        if (isRooted != null && isRooted) return true;
      }
      final String? result = await Root.exec(cmd: 'id');
      return result != null && (result.contains('uid=0') || result.contains('root'));
    } catch (e) {
      if (kDebugMode) {
        print('Root check failed: $e');
      }
      return false;
    }
  }

  Future<void> setPermissions(
    String permissions,
    String ownerGroup,
    String seLinux,
    String filePath,
  ) async {
    try {
      final StringBuffer commands = StringBuffer();
      if (permissions.isNotEmpty) {
        commands.writeln('chmod $permissions "$filePath"');
      }
      if (ownerGroup.isNotEmpty) {
        commands.writeln('chown $ownerGroup "$filePath"');
      }
      if (seLinux.isNotEmpty) {
        commands.writeln('chcon $seLinux "$filePath"');
      }
      await Root.exec(cmd: commands.toString());
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    if (packageName.isNotEmpty) {
      return fileExists('$_modulesDirPath/$packageName-mounter/service.sh');
    }
    return false;
  }

  Future<List<String>> getInstalledApps() async {
    final List<String> apps = List.empty(growable: true);
    try {
      final String? res = await Root.exec(cmd: 'ls $_modulesDirPath');
      if (res != null) {
        final List<String> list = res.split('\n');
        for (var dir in list) {
          dir = dir.trim();
          if (dir.endsWith('-mounter')) {
            final pkg = dir.substring(0, dir.length - '-mounter'.length);
            apps.add(pkg);
          }
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return apps;
  }

  Future<void> uninstall(String packageName) async {
    final String modulePath = '$_modulesDirPath/$packageName-mounter';
    
    final String script = r'''
          grep __PKG_NAME__ /proc/mounts | while read -r line; do echo $line | cut -d " " -f 2 | sed "s/apk.*/apk/" | xargs -r umount -l; done
          am force-stop __PKG_NAME__
          rm -rf "__MODULE_PATH__"
    '''.replaceAll('__PKG_NAME__', packageName).replaceAll('__MODULE_PATH__', modulePath);

    await Root.exec(cmd: script);
  }

  Future<void> removeOrphanedFiles() async {
    // Removed old orphaned file logic as we now use module directory
  }

  Future<bool> install(
    String packageName,
    String originalFilePath,
    String patchedFilePath, {
    String version = '',
    String label = '',
  }) async {
    try {
      final String modulePath = '$_modulesDirPath/$packageName-mounter';
      await Root.exec(cmd: 'mkdir -p $modulePath');
      
      await installPatchedApk(packageName, patchedFilePath);
      await _installModuleProp(packageName, version, label, modulePath);
      await _installServiceSh(packageName, version, modulePath);
      
      await runMountScript(packageName);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<void> _installModuleProp(String packageName, String version, String label, String modulePath) async {
    String content = _modulePropTemplate
        .replaceAll('__PKG_NAME__', packageName)
        .replaceAll('__VERSION__', version)
        .replaceAll('__LABEL__', label);
    
    // Write content out securely
    await Root.exec(cmd: "cat << 'EOF' > $modulePath/module.prop\n$content\nEOF");
  }

  Future<void> _installServiceSh(String packageName, String version, String modulePath) async {
    String content = _serviceShTemplate
        .replaceAll('__PKG_NAME__', packageName)
        .replaceAll('__VERSION__', version);
    
    await Root.exec(cmd: "cat << 'EOF' > $modulePath/service.sh\n$content\nEOF");
    await setPermissions('0744', '', '', '$modulePath/service.sh');
  }

  Future<void> installPatchedApk(String packageName, String patchedFilePath) async {
    final String modulePath = '$_modulesDirPath/$packageName-mounter';
    final String newPatchedFilePath = '$modulePath/$packageName.apk';
    await Root.exec(
      cmd: 'cp "$patchedFilePath" "$newPatchedFilePath"',
    );
    await setPermissions(
      '0644',
      'system:system',
      'u:object_r:apk_data_file:s0',
      newPatchedFilePath,
    );
  }

  Future<void> runMountScript(String packageName) async {
    final String patchedApk = '$_modulesDirPath/$packageName-mounter/$packageName.apk';
    
    final String script = r'''
      stock_path_data="$(pm path "__PKG_NAME__" | grep base | grep /data/app/ | head -n 1 | sed 's/package://g')"
      stock_path_fallback="$(pm path "__PKG_NAME__" | grep base | head -n 1 | sed 's/package://g')"
      if [ -z "$stock_path_data" ] && [ -z "$stock_path_fallback" ]; then
        stock_path_cmd="$(cmd package path "__PKG_NAME__" 2>/dev/null | grep base | head -n 1 | sed 's/package://g')"
      else
        stock_path_cmd=""
      fi
      stock_path_res="${stock_path_data:-${stock_path_fallback:-$stock_path_cmd}}"

      if [ -n "$stock_path_res" ] && [ -f "$stock_path_res" ]; then
        chcon u:object_r:apk_data_file:s0 "__PATCHED_APK__"
        mount -o bind "__PATCHED_APK__" "$stock_path_res"
        am force-stop "__PKG_NAME__"
      fi
    '''.replaceAll('__PKG_NAME__', packageName).replaceAll('__PATCHED_APK__', patchedApk);

    await Root.exec(cmd: script);
  }

  Future<bool> fileExists(String path) async {
    try {
      final String? res = await Root.exec(cmd: 'ls "$path"');
      return res != null && res.isNotEmpty;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }
}
