import 'package:flutter/material.dart';

class MyColors{
  MyColors._();


  // App Basic Colors
  static const Color primaryColor = Color(0xFF1E7B7F);
  static const Color secondaryColor = Color(0xFF47FFA4);
  static const Color accent = Color(0xFFCBC811);

  // Gradient Colors
  static const Gradient linearGradient = LinearGradient(
    begin: Alignment(0.0, 0.0),
    end: Alignment(0.0, 0.0),
    colors: [
      Color(0xFF1E7B7F),
      Color(0xFF47FFA4),
      Color(0xFFCBC811),
    ],
  );


  // Text Colors
  static const Color textPrimary = Color(0xFFD7D7D7);
  static const Color textSecondary = Color(0xFF2C2C2C);
  static const Color textWhite = Colors.white;

  // Background Colors
  static const Color light = Color(0xFFD7D7D7);
  static const Color transparent = Color(0x00948686);
  static const Color dark = Color(0xFF2C2C2C);
  static const Color primaryBackground = Color(0xFFD7D7D7);

  // Background Container Colors
  static const Color lightContainer = Color(0xFFD7D7D7);
  static const Color darkContainer = Color(0xFF2C2C2C);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF218F7D);
  static const Color buttonSecondary = Color(0xFF528A85);
  static const Color buttonTertiary = Color(0xFF9C905F);
  static const Color buttonDisabled = Color(0xFFD2D2D2);

  // Border Colors
  static const Color borderPrimary = Color(0xFF1118F1);
  static const Color borderSecondary = Color(0xFF1118F1);

  // Error and Validation Colors
  static const Color error = Color(0xFFF11118);
  static const Color success = Color(0xFF00FFD1);
  static const Color warning = Color(0xFFF5E100);
  static const Color info = Color(0xFF1118F1);

  // Neutral Shades
  static const Color black = Color(0xFF090909);
  static const Color darkerGrey = Color(0xF4444444);
  static const Color darkGrey  = Color(0xFA595959);
  static const Color grey = Color(0xFF7C7C7C);
  static const Color softGrey = Color(0xF49A9A9A);
  static const Color lightGrey  = Color(0xFAC9C9C9);
  static const Color white = Color(0xFFFAFAFA);



}


