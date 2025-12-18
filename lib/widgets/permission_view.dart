import 'package:flutter/material.dart';

class PermissionView extends StatelessWidget {
  final String permissionName;
  final VoidCallback onRequest;

  const PermissionView({
    super.key,
    required this.permissionName,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 80,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 24),
            Text(
              '$permissionName Permission Required',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs $permissionName permission to access and mount APK files.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.check_circle),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
