import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/height_estimation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/image_preview_screen.dart';
import 'screens/results_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow Google Fonts to fetch fonts at runtime
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HeightEstimationProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppConstants.homeRoute,
        routes: {
          AppConstants.homeRoute: (context) => const HomeScreen(),
          AppConstants.imagePreviewRoute: (context) =>
              const ImagePreviewScreen(),
          AppConstants.resultsRoute: (context) => const ResultsScreen(),
          AppConstants.profileRoute: (context) => const ProfileScreen(),
          AppConstants.historyRoute: (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
