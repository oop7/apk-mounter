import 'package:flutter/material.dart';
import 'package:apk_mounter/services/mount_manager.dart';
import 'package:apk_mounter/models/mounted_app.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:apk_mounter/services/theme_provider.dart';
import 'package:apk_mounter/widgets/permission_view.dart';
import 'package:apk_mounter/widgets/no_root_view.dart';
import 'package:apk_mounter/widgets/mounted_apps_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.apkmounter.app/apk_info');
  final MountManager _mountManager = MountManager();
  List<MountedApp> _mountedApps = [];
  bool _isLoading = true;
  bool _hasRootAccess = false;
  bool _hasStoragePermission = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    // Check and request storage permission
    await _checkStoragePermission();

    // Request and check root access
    _hasRootAccess = await _mountManager.requestRootAccess();

    if (_hasRootAccess && _hasStoragePermission) {
      await _loadMountedApps();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkStoragePermission() async {
    if (await Permission.storage.isGranted) {
      _hasStoragePermission = true;
    } else if (await Permission.manageExternalStorage.isGranted) {
      _hasStoragePermission = true;
    } else {
      // Request permission
      final status = await Permission.manageExternalStorage.request();
      _hasStoragePermission = status.isGranted;
      
      if (!_hasStoragePermission) {
        // Try regular storage permission as fallback
        final storageStatus = await Permission.storage.request();
        _hasStoragePermission = storageStatus.isGranted;
      }
    }
  }

  Future<void> _loadMountedApps() async {
    try {
      final apps = await _mountManager.getMountedApps();
      setState(() => _mountedApps = apps);
    } catch (e) {
      _showSnackBar('Error loading mounted apps: $e');
    }
  }

  Future<void> _pickAndMountAPK() async {
    if (!_hasStoragePermission) {
      _showSnackBar('Storage permission required');
      await _checkStoragePermission();
      return;
    }

    // Pick APK file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result != null && result.files.single.path != null) {
      final apkPath = result.files.single.path!;

      // Try to get package name automatically
      String? packageName;
      try {
        packageName = await platform.invokeMethod('getPackageName', {'apkPath': apkPath});
        if (packageName != null) {
          _showSnackBar('Detected package: $packageName');
        }
      } catch (e) {
        print('Failed to get package name: $e');
      }

      // If failed, ask user
      if (packageName == null || packageName.isEmpty) {
        packageName = await _showPackageNameDialog();
      }

      if (packageName != null && packageName.isNotEmpty) {
        // Validate package name format
        if (!_isValidPackageName(packageName)) {
          _showSnackBar('Invalid package name format (e.g., com.example.app)');
          return;
        }

        // Check if target app is installed
        final isInstalled = await DeviceApps.isAppInstalled(packageName);
        if (!isInstalled) {
          final shouldContinue = await _showConfirmDialog(
            'App Not Installed',
            'The app $packageName is not installed on this device. The mount will be created but won\'t work until you install the app. Continue?',
          );
          if (shouldContinue != true) return;
        }

        // Check if already mounted
        final alreadyMounted = await _mountManager.isAppMounted(packageName);
        if (alreadyMounted) {
          _showSnackBar('This app is already mounted. Unmount it first.');
          return;
        }

        setState(() => _isLoading = true);

        try {
          // Copy APK to accessible location
          final copiedPath = await _copyAPKToTemp(apkPath);
          
          final success = await _mountManager.mountAPK(packageName, copiedPath);

          if (success) {
            _showSnackBar('APK mounted successfully!');
            await _loadMountedApps();
          } else {
            _showSnackBar('Failed to mount APK. Check root permissions.');
          }
        } catch (e) {
          _showSnackBar('Error: $e');
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<String> _copyAPKToTemp(String originalPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = originalPath.split('/').last;
    final tempPath = '${tempDir.path}/$fileName';
    
    await File(originalPath).copy(tempPath);
    return tempPath;
  }

  bool _isValidPackageName(String packageName) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
    return regex.hasMatch(packageName);
  }

  Future<String?> _showPackageNameDialog() async {
    String packageName = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Package Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the package name of the app you want to replace:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => packageName = value,
              decoration: const InputDecoration(
                hintText: 'com.example.app',
                labelText: 'Package Name',
                helperText: 'Example: com.android.chrome',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: You can find package names in Settings > Apps',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, packageName),
            child: const Text('Mount'),
          ),
        ],
      ),
    );
  }

  Future<void> _unmountApp(MountedApp app) async {
    final confirm = await _showConfirmDialog(
      'Unmount ${app.appName}?',
      'This will remove the mounted APK and restore the original app.',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _mountManager.unmountApp(app.packageName);
        _showSnackBar('${app.appName} unmounted.');
        await _loadMountedApps();
      } catch (e) {
        _showSnackBar('Error unmounting: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _remountApp(MountedApp app) async {
    setState(() => _isLoading = true);

    try {
      final success = await _mountManager.remountApp(app.packageName);
      if (success) {
        _showSnackBar('${app.appName} remounted successfully.');
      } else {
        _showSnackBar('Failed to remount ${app.appName}.');
      }
    } catch (e) {
      _showSnackBar('Error remounting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPermissionsHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Required Permissions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Root Access',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'This app requires root access to mount APK files. Make sure your device is rooted with Magisk or similar.',
              ),
              SizedBox(height: 12),
              Text(
                '2. Storage Permission',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Storage access is needed to read APK files you want to mount.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK Mounter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPermissionsHelp,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initialize,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasStoragePermission
              ? PermissionView(
                  permissionName: 'Storage',
                  onRequest: () async {
                    await _checkStoragePermission();
                    setState(() {});
                  },
                )
              : !_hasRootAccess
                  ? NoRootView(
                      onRefresh: _initialize,
                      onHelp: _showPermissionsHelp,
                    )
                  : MountedAppsList(
                      mountedApps: _mountedApps,
                      onUnmount: _unmountApp,
                      onRemount: _remountApp,
                      onHelp: _showPermissionsHelp,
                    ),
      floatingActionButton: (_hasRootAccess && _hasStoragePermission)
          ? FloatingActionButton.extended(
              onPressed: _pickAndMountAPK,
              label: const Text('Mount APK'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
