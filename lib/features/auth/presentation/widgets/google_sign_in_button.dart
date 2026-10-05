import 'package:flutter/material.dart';
import 'package:topik_go/app/theme/app_colors.dart';

/// Official Google 'G' 4-color vector logo rendered via CustomPainter.
/// Infinitely crisp at any screen density without external asset dependencies.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const GoogleLogoPainter(),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;

    // Red (Top)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final redPath = Path()
      ..moveTo(24.00 * s, 9.50 * s)
      ..cubicTo(27.54 * s, 9.50 * s, 30.71 * s, 10.72 * s, 33.21 * s, 13.10 * s)
      ..lineTo(40.06 * s, 6.25 * s)
      ..cubicTo(35.90 * s, 2.38 * s, 30.47 * s, 0.00 * s, 24.00 * s, 0.00 * s)
      ..cubicTo(14.62 * s, 0.00 * s, 6.51 * s, 5.38 * s, 2.56 * s, 13.22 * s)
      ..lineTo(10.54 * s, 19.41 * s)
      ..cubicTo(12.43 * s, 13.72 * s, 17.74 * s, 9.50 * s, 24.00 * s, 9.50 * s)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Blue (Right & Bar)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final bluePath = Path()
      ..moveTo(46.98 * s, 24.55 * s)
      ..cubicTo(46.98 * s, 22.98 * s, 46.83 * s, 21.46 * s, 46.60 * s, 20.00 * s)
      ..lineTo(24.00 * s, 20.00 * s)
      ..lineTo(24.00 * s, 29.02 * s)
      ..lineTo(36.94 * s, 29.02 * s)
      ..cubicTo(36.36 * s, 31.98 * s, 34.68 * s, 34.50 * s, 32.16 * s, 36.20 * s)
      ..lineTo(39.89 * s, 42.20 * s)
      ..cubicTo(44.40 * s, 38.02 * s, 46.98 * s, 31.84 * s, 46.98 * s, 24.55 * s)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Yellow (Bottom-Left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final yellowPath = Path()
      ..moveTo(10.53 * s, 28.59 * s)
      ..cubicTo(10.05 * s, 27.14 * s, 9.77 * s, 25.60 * s, 9.77 * s, 24.00 * s)
      ..cubicTo(9.77 * s, 22.40 * s, 10.04 * s, 20.86 * s, 10.53 * s, 19.41 * s)
      ..lineTo(2.55 * s, 13.22 * s)
      ..cubicTo(0.92 * s, 16.46 * s, 0.00 * s, 20.12 * s, 0.00 * s, 24.00 * s)
      ..cubicTo(0.00 * s, 27.88 * s, 0.92 * s, 31.54 * s, 2.56 * s, 34.78 * s)
      ..lineTo(10.53 * s, 28.59 * s)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Green (Bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final greenPath = Path()
      ..moveTo(24.00 * s, 48.00 * s)
      ..cubicTo(30.48 * s, 48.00 * s, 35.93 * s, 45.87 * s, 39.89 * s, 42.19 * s)
      ..lineTo(32.16 * s, 36.19 * s)
      ..cubicTo(30.01 * s, 37.64 * s, 27.24 * s, 38.49 * s, 24.00 * s, 38.49 * s)
      ..cubicTo(17.74 * s, 38.49 * s, 12.43 * s, 34.27 * s, 10.53 * s, 28.58 * s)
      ..lineTo(2.55 * s, 34.77 * s)
      ..cubicTo(6.51 * s, 42.62 * s, 14.62 * s, 48.00 * s, 24.00 * s, 48.00 * s)
      ..close();
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Polished Google Sign-In button adhering to modern mobile UI design and
/// Google Identity guidelines: clean white surface, subtle border, authentic
/// 4-color 'G' logo, balanced typography, and responsive ripple/loading state.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Google 계정으로 계속하기',
    this.isLoading = false,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isInteractive || isLoading ? 1.0 : 0.6,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: const Color(0x1A4285F4),
            highlightColor: const Color(0x0D000000),
            onTap: isInteractive ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const Center(
                        key: ValueKey('loading'),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.mintDark,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleLogo(size: 22),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
