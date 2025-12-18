import 'package:flutter/material.dart';

class NoRootView extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onHelp;

  const NoRootView({
    super.key,
    required this.onRefresh,
    required this.onHelp,
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
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Root Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This app requires root access to mount APK files. '
              'Please ensure your device is rooted with Magisk or similar, '
              'and grant root permissions when prompted.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onHelp,
              icon: const Icon(Icons.help_outline),
              label: const Text('Learn More'),
            ),
          ],
        ),
      ),
    );
  }
}
