import 'package:flutter/material.dart';

import 'package:ccet_alumini_app/services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:ccet_alumini_app/screens/splash_screen.dart';

import 'package:provider/provider.dart';
import 'package:ccet_alumini_app/providers/theme_provider.dart';
import 'package:ccet_alumini_app/services/notification_service.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  TextTheme getFontTheme(String font, TextTheme baseTheme) {
    switch (font) {
      case 'Plus Jakarta Sans':
        return GoogleFonts.plusJakartaSansTextTheme(baseTheme);
      case 'Satoshi (Outfit)':
        return GoogleFonts.outfitTextTheme(baseTheme);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplayTextTheme(baseTheme);
      case 'Poppins':
      default:
        return GoogleFonts.poppinsTextTheme(baseTheme);
    }
  }

  TextStyle getFontStyle(String font, {FontWeight? fontWeight}) {
    switch (font) {
      case 'Plus Jakarta Sans':
        return GoogleFonts.plusJakartaSans(fontWeight: fontWeight);
      case 'Satoshi (Outfit)':
        return GoogleFonts.outfit(fontWeight: fontWeight);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontWeight: fontWeight);
      case 'Poppins':
      default:
        return GoogleFonts.poppins(fontWeight: fontWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final font = themeProvider.fontFamily;

    // Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF2575FC), // Blue
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Light Grey/White
      textTheme: getFontTheme(font, ThemeData.light().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2575FC),
        secondary: const Color(0xFF00C6FF), // Light Blue Accent
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // For gradient backgrounds
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2575FC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: getFontStyle(font, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2575FC), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

    // Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF2575FC),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: getFontTheme(
        font,
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2575FC),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2575FC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: getFontStyle(font, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        color: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2575FC), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CCET Alumni',
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      builder: (context, child) {
        final scale = themeProvider.textScaleFactor;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              (MediaQuery.of(context).textScaleFactor * scale).clamp(0.8, 2.0),
            ),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
