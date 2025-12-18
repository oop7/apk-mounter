import 'package:flutter/material.dart';
import 'package:apk_mounter/models/mounted_app.dart';

class MountedAppsList extends StatelessWidget {
  final List<MountedApp> mountedApps;
  final Function(MountedApp) onUnmount;
  final Function(MountedApp) onRemount;
  final VoidCallback onHelp;

  const MountedAppsList({
    super.key,
    required this.mountedApps,
    required this.onUnmount,
    required this.onRemount,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    if (mountedApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No mounted apps',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to mount an APK',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onHelp,
              icon: const Icon(Icons.info_outline),
              label: const Text('How it works'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: mountedApps.length,
      itemBuilder: (context, index) {
        final app = mountedApps[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: MemoryImage(app.icon),
            ),
            title: Text(app.appName),
            subtitle: Text('${app.packageName}\nVersion: ${app.versionName}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => onRemount(app),
                  tooltip: 'Remount',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onUnmount(app),
                  tooltip: 'Unmount',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
