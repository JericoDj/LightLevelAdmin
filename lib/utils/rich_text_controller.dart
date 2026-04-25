import 'package:flutter/material.dart';

const List<Color> mindHubTextColors = [
  Colors.black,
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Color(0xFFfd9c33), // Brand Orange
];

class MindHubRichTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<TextSpan> children = [];
    final String textContent = text;
    
    // Regex to match tags and normal text
    final RegExp regExp = RegExp(r'(<[^>]+>)|([^<]+)');
    final Iterable<Match> matches = regExp.allMatches(textContent);
    
    TextStyle baseStyle = style ?? const TextStyle();
    List<TextStyle> styleStack = [baseStyle];

    for (final Match match in matches) {
      final String part = match.group(0)!;
      if (part.startsWith('<')) {
        // Tag handling
        if (part.startsWith('</')) {
          if (styleStack.length > 1) styleStack.removeLast();
        } else {
          TextStyle nextStyle = styleStack.last;
          if (part == '<b>') {
            nextStyle = nextStyle.copyWith(fontWeight: FontWeight.bold);
          } else if (part == '<i>') {
            nextStyle = nextStyle.copyWith(fontStyle: FontStyle.italic);
          } else if (part == '<u>') {
            nextStyle = nextStyle.copyWith(decoration: TextDecoration.underline);
          } else if (part.startsWith('<color=')) {
            try {
              final hex = part.substring(7, 14);
              nextStyle = nextStyle.copyWith(color: Color(int.parse(hex.replaceFirst('#', '0xFF'))));
            } catch (_) {}
          }
          styleStack.add(nextStyle);
        }
        // Render tag subtly
        children.add(TextSpan(
          text: part,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.normal, fontStyle: FontStyle.normal, decoration: TextDecoration.none),
        ));
      } else {
        // Text content handling
        children.add(TextSpan(text: part, style: styleStack.last));
      }
    }

    return TextSpan(children: children);
  }
}
