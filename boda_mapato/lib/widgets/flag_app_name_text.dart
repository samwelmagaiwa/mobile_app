import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the app name as one continuous Tanzania-flag diagonal (green ->
/// yellow -> black -> yellow -> blue) clipped through the letters via a
/// gradient shader -- so a single letter can show two colors where the
/// diagonal cuts across it, exactly like the real flag, rather than each
/// letter being one flat color. Each letter still gets a different bold
/// display font cycled across the word for a playful logotype look; the
/// shader only replaces color, not shape, so the font mix is preserved.
class FlagAppNameText extends StatelessWidget {
  const FlagAppNameText(
    this.text, {
    super.key,
    this.fontSize = 28,
  });

  final String text;
  final double fontSize;

  // Official Tanzania flag palette and its real diagonal-band proportions
  // (two thin yellow edges around a black band, green/blue as the two big
  // triangles), widened slightly so each band still reads clearly across a
  // short word instead of vanishing as a sliver.
  static const List<Color> _bandColors = <Color>[
    Color(0xFF1EB53A),
    Color(0xFFFCD116),
    Color(0xFF141414),
    Color(0xFFFCD116),
    Color(0xFF00A3DD),
  ];
  static const List<double> _bandStops = <double>[0.0, 0.38, 0.44, 0.58, 0.64];

  static final List<TextStyle Function(double)> _fontStyles =
      <TextStyle Function(double)>[
    (double size) => GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w900),
    (double size) => GoogleFonts.montserrat(fontSize: size, fontWeight: FontWeight.w800),
    (double size) => GoogleFonts.baloo2(fontSize: size, fontWeight: FontWeight.w700),
    (double size) => GoogleFonts.rubik(fontSize: size, fontWeight: FontWeight.w800),
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> chars = text.split('');
    int letterIndex = 0;
    final List<TextSpan> spans = <TextSpan>[];
    for (final String ch in chars) {
      if (ch.trim().isEmpty) {
        spans.add(TextSpan(
          text: ' ',
          style: TextStyle(fontSize: fontSize * 0.6),
        ));
        continue;
      }
      final TextStyle style = _fontStyles[letterIndex % _fontStyles.length](fontSize)
          .copyWith(color: Colors.white, height: 1);
      spans.add(TextSpan(text: ch, style: style));
      letterIndex++;
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _bandColors,
        stops: _bandStops,
      ).createShader(bounds),
      child: RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.center,
      ),
    );
  }
}
