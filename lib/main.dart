import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';

import 'services/thumbnail_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize persistent thumbnail storage to solve loading speed issues
  await ThumbnailService.init();
  
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News & Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppTheme.bgDark,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
