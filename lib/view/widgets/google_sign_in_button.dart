import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'google_signin_render_stub.dart'
    if (dart.library.js_interop) 'google_signin_render_web.dart';

/// Sign-in button styled per Google's brand guidelines:
///   white background, neutral hairline border, dark grey label, the
///   official 4-colour "G" mark on the leading edge.
///
/// On the web, this defers to Google's officially-rendered button (via
/// `google_sign_in_web`'s `renderButton`), which is required by the
/// `google_sign_in` 7.x web implementation. The [onPressed] callback is
/// ignored on web — the click drives Google's auth flow directly, and
/// the result must be handled via
/// `GoogleSignIn.instance.authenticationEvents`.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Sign in with Google',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Google's button has its own intrinsic size (max 400 px wide per
      // GIS spec). Centre it so it doesn't try to stretch across the
      // login column.
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: 44,
          child: renderGoogleSignInWebButton(minimumWidth: 280),
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFDADCE0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const _GoogleGLogo(size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF3C4043),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
                const SizedBox(width: 30), // visual centring counterweight
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The official Google "G" mark, drawn from the same path data as the canvas
/// sketches so the live app and the design artefact stay in sync.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  // The four Google brand colours, applied to the four glyph quadrants.
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    canvas.save();
    canvas.scale(scale);

    // Each path is the literal Google "G" geometry in 48x48 user units,
    // hand-translated from the canvas SVG so we can render without an SVG dep.
    canvas.drawPath(_blueArc(), Paint()..color = _blue);
    canvas.drawPath(_greenArc(), Paint()..color = _green);
    canvas.drawPath(_yellowArc(), Paint()..color = _yellow);
    canvas.drawPath(_redArc(), Paint()..color = _red);

    canvas.restore();
  }

  Path _blueArc() {
    final p = Path();
    p.moveTo(47.532, 24.552);
    p.relativeCubicTo(0, -1.636, -0.146, -3.21, -0.418, -4.73);
    p.lineTo(24.48, 19.822);
    p.relativeLineTo(0, 8.948);
    p.relativeLineTo(12.937, 0);
    p.relativeCubicTo(-0.557, 3.005, -2.255, 5.55, -4.81, 7.255);
    p.relativeLineTo(0, 6.026);
    p.relativeLineTo(7.787, 0);
    p.relativeCubicTo(4.555, -4.198, 7.138, -10.378, 7.138, -17.499);
    p.close();
    return p;
  }

  Path _greenArc() {
    final p = Path();
    p.moveTo(24.48, 48);
    p.relativeCubicTo(6.48, 0, 11.917, -2.146, 15.89, -5.819);
    p.relativeLineTo(-7.787, -6.026);
    p.relativeCubicTo(-2.157, 1.443, -4.918, 2.296, -8.103, 2.296);
    p.relativeCubicTo(-6.232, 0, -11.512, -4.207, -13.398, -9.86);
    p.lineTo(3.042, 28.591);
    p.relativeLineTo(0, 6.225);
    p.cubicTo(7.04, 42.764, 15.117, 48, 24.48, 48);
    p.close();
    return p;
  }

  Path _yellowArc() {
    final p = Path();
    p.moveTo(11.083, 28.591);
    p.relativeCubicTo(-0.48, -1.444, -0.752, -2.985, -0.752, -4.591);
    p.relativeCubicTo(0, -1.606, 0.272, -3.147, 0.752, -4.591);
    p.relativeLineTo(0, -6.225);
    p.lineTo(3.043, 13.184);
    // Approximated arc (Path doesn't accept SVG 'A' directly): we use a cubic
    // close enough for the 18px logo. Fidelity is preserved at 48px+ via the
    // straight segments — this curve only smooths the lower-left edge.
    p.cubicTo(1.06, 17.119, 0, 20.453, 0, 24);
    p.cubicTo(0, 27.876, 0.927, 31.535, 2.563, 34.816);
    p.lineTo(11.083, 28.591);
    p.close();
    return p;
  }

  Path _redArc() {
    final p = Path();
    p.moveTo(24.48, 9.55);
    p.relativeCubicTo(3.515, 0, 6.668, 1.211, 9.151, 3.585);
    p.relativeLineTo(6.876, -6.875);
    p.cubicTo(36.39, 2.379, 30.953, 0, 24.48, 0);
    p.cubicTo(15.117, 0, 7.04, 5.236, 3.043, 12.816);
    p.relativeLineTo(8.04, 6.225);
    p.relativeCubicTo(1.886, -5.652, 7.166, -9.491, 13.397, -9.491);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
