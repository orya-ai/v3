import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define color constants
  static const Color primaryBackgroundColor = Color(0xffefedec); // Light beige for header/footer
  static const Color scaffoldBackgroundColor = Color(0xffFFFFFF); // White for main content
  static const Color primaryTextColor = Color(0xFF3B3B3B);
  static const Color accentColor = Color(0xFF3B3B3B);
  static const Color headerFooterColor = Color(0xffFFFFFF); // Same as primaryBackgroundColor for clarity

    static const Color primaryButtonColor = Color(0xFF3B3B3B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor, // Main content background
      canvasColor: scaffoldBackgroundColor, // For dialogs and other surfaces
      cardColor: Colors.white, // For cards and other surfaces
      dialogBackgroundColor: Colors.white, // For dialogs
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        background: scaffoldBackgroundColor, // Main content background
        surface: Colors.white, // Surface color for cards, sheets, menus, etc.
        primary: accentColor, // Primary interactive elements
        onBackground: primaryTextColor, // Text/icons on background
        onSurface: primaryTextColor, // Text/icons on surface
        onPrimary: Colors.white, // Text/icons on primary color elements
        // You can define other colors like secondary, error, etc.
      ),
      textTheme: GoogleFonts.interTextTheme(
        // Base text theme for good contrast, can be further customized
        ThemeData.light().textTheme.apply(
          bodyColor: primaryTextColor,
          displayColor: primaryTextColor,
        ),
      ),
      // App bar theme - using header/footer color
      appBarTheme: AppBarTheme(
        backgroundColor: headerFooterColor,
        elevation: 0, // Flat app bars
        iconTheme: const IconThemeData(color: primaryTextColor),
        titleTextStyle: GoogleFonts.inter(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Bottom app bar theme - using header/footer color
      bottomAppBarTheme: const BottomAppBarTheme(
        color: headerFooterColor,
        elevation: 0,
      ),
      // Define other component themes as needed (buttons, cards, etc.)
    );
  }

  // Optionally, define a darkTheme here in the future
  // static ThemeData get darkTheme { ... }
}
