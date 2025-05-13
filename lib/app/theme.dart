import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    appBarTheme: const AppBarTheme(
      color: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFF3B3B3B),),
      titleTextStyle: TextStyle(
        color: Color(0xFF3B3B3B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Colors.blueAccent,
      textTheme: ButtonTextTheme.primary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),  // Updated
      bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400), // Updated
    ),
  );
}