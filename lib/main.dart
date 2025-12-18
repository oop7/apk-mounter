import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:apk_mounter/screens/home_screen.dart';
import 'package:apk_mounter/services/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const APKMounterApp(),
    ),
  );
}

class APKMounterApp extends StatelessWidget {
  const APKMounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.copyWith();
          darkScheme = darkDynamic.copyWith();
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'APK Mounter',
              theme: ThemeData(
                colorScheme: lightScheme,
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: true,
              ),
              themeMode: themeProvider.themeMode,
              home: const HomeScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
