import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';

/// Two-panel auth layout.
///
/// The artwork bleeds to the window edge: no SafeArea, no padding, no
/// rounded corners. Any inset there reads as an accidental border rather
/// than a designed margin.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: p.paper,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) const Expanded(flex: 5, child: _ArtPanel()),
          Expanded(
            flex: 4,
            // SafeArea only on the form side, where clipped content
            // would actually matter.
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtPanel extends StatelessWidget {
  const _ArtPanel();

  static const _textColour = Color(0xFFFFECEC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale from the shorter side, so a tall narrow panel and a wide
        // short one both get type that suits the space. Width alone makes
        // the headline stall on large screens while the panel keeps growing.
        final base = constraints.biggest.shortestSide / 100;
        final leadSize = (base * 4.2).clamp(15.0, 40.0);
        final headlineSize = (base * 14.7).clamp(40.0, 150.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/auth-backdrop.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF14130F)),
            ),
            // Keeps the text legible if the photo lightens behind it.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x80000000)],
                ),
              ),
            ),


            Padding(
              // Margins grow with the panel, so the block keeps the same
              // proportion of breathing room at every size.
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * 0.08,
                0,
                constraints.maxWidth * 0.08,
                constraints.maxHeight * 0.09,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Scales down rather than overflowing when the panel is
                  // too short for the type size the width implies.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Eat well\non your terms\nYour food, your goals your data',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.leagueSpartan(
                              color: _textColour,
                              fontSize: leadSize,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: leadSize * 1.1),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Nutri'),
                                TextSpan(
                                  text: 'AI',
                                  style: TextStyle(
                                    color: context.palette.turmeric,
                                  ),
                                ),
                                const TextSpan(text: ' keeps all\nthree yours'),
                              ],
                            ),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.leagueSpartan(
                              color: _textColour,
                              fontSize: headlineSize,
                              fontWeight: FontWeight.w700,
                              height: 0.95,
                              letterSpacing: headlineSize * -0.015,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        );
      },
    );
  }
}