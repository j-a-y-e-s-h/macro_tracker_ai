import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

import 'package:openfoodfacts/openfoodfacts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'MacroMate',
    url: 'https://github.com/macromate', // Placeholder
  );
  
  // Initialize Firebase if configured
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   debugPrint('Firebase not initialized: $e');
  // }

  runApp(const ProviderScope(child: MacroTrackerApp()));
}

class MacroTrackerApp extends StatelessWidget {
  const MacroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MacroMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
