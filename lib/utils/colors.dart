import 'package:flutter/material.dart';

class MyColors {
  // Primary Colors
  static const Color color1 = Color(0xFF059646); // Green from Image 1
  static const Color color2 = Color(0xFFfd9c33); // Orange from Image 2
  static const Color color3 = Color(0xFFFAA92B); // Light Orange from Image 3
  static const Color color4 = Color(0xFF359D4E); // Green from Image 4
  static const Color color5 = Color(0xFF57B14D); // Bright Green from Image 5
  static const Color color6 = Color(0xFFFDA039); // Orange from Image 6
  static const Color color7 = Color(0xFFF68E1D); // Dark Orange from Image 7

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color black = Color(0xFF000000); // Black
  static const Color greyLight = Color(0xFFE0E0E0); // Light Grey
  static const Color greyDark = Color(0xFF616161); // Dark Grey
}

// Example usage in a widget:
class ColorPaletteDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Color Palette Demo'),
        backgroundColor: MyColors.color1, // Example color
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
              Container(color: MyColors.color1, child: Center(child: Text('Color 1'))),
          Container(color: MyColors.color2, child: Center(child: Text('Color 2'))),
          Container(color: MyColors.color3, child: Center(child: Text('Color 3'))),
          Container(color: MyColors.color4, child: Center(child: Text('Color 4'))),
          Container(color: MyColors.color5, child: Center(child: Text('Color 5'))),
          Container(color: MyColors.color6, child: Center(child: Text('Color 6'))),
          Container(color: MyColors.color7, child: Center(child: Text('Color 7'))),
          Container(color: MyColors.white, child: Center(child: Text('White'))),
          Container(color: MyColors.black, child: Center(child: Text('Black', style: TextStyle(color: Colors.white)))),
          Container(color: MyColors.greyLight, child: Center(child: Text('Light Grey'))),
          Container(color: MyColors.greyDark, child: Center(child: Text('Dark Grey', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }
}
