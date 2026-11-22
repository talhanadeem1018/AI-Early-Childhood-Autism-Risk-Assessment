import 'dart:math' as math;
import 'package:flutter/material.dart';

class NurseMascot extends StatefulWidget {
  const NurseMascot({super.key, this.size = 190});

  final double size;

  @override
  State<NurseMascot> createState() => _NurseMascotState();
}

class _NurseMascotState extends State<NurseMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final movement = math.sin(_controller.value * math.pi) * 5;
        final wave = math.sin(_controller.value * math.pi * 2) * 0.12;

        return Transform.translate(
          offset: Offset(0, -movement),
          child: SizedBox(
            width: widget.size,
            height: widget.size * 1.08,
            child: CustomPaint(painter: _NursePainter(wave: wave)),
          ),
        );
      },
    );
  }
}

class _NursePainter extends CustomPainter {
  _NursePainter({required this.wave});

  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.save();
    canvas.scale(scale);

    final shadow = Paint()..color = const Color(0x18345F65);
    canvas.drawOval(const Rect.fromLTWH(48, 184, 104, 12), shadow);

    final skin = Paint()..color = const Color(0xFFFFD6BD);
    final uniform = Paint()..color = const Color(0xFF55A6A3);
    final dark = Paint()..color = const Color(0xFF235B68);
    final white = Paint()..color = Colors.white;
    final line = Paint()
      ..color = const Color(0xFF235B68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(75, 158, 19, 32),
        const Radius.circular(9),
      ),
      dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(106, 158, 19, 32),
        const Radius.circular(9),
      ),
      dark,
    );

    // Shoes
    canvas.drawOval(const Rect.fromLTWH(68, 183, 34, 12), dark);
    canvas.drawOval(const Rect.fromLTWH(101, 183, 34, 12), dark);

    // Body
    final body = Path()
      ..moveTo(72, 93)
      ..quadraticBezierTo(100, 82, 128, 93)
      ..lineTo(145, 163)
      ..quadraticBezierTo(101, 178, 56, 163)
      ..close();
    canvas.drawPath(body, uniform);

    // White coat details
    final coat = Path()
      ..moveTo(87, 91)
      ..lineTo(100, 111)
      ..lineTo(113, 91)
      ..lineTo(126, 164)
      ..lineTo(74, 164)
      ..close();
    canvas.drawPath(coat, white);

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(90, 76, 20, 24),
        const Radius.circular(7),
      ),
      skin,
    );

    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(51, 105, 19, 57),
        const Radius.circular(10),
      ),
      uniform,
    );
    canvas.drawCircle(const Offset(60, 161), 9, skin);

    // Waving arm
    canvas.save();
    canvas.translate(132, 105);
    canvas.rotate(wave - 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -8, 19, 53),
        const Radius.circular(10),
      ),
      uniform,
    );
    canvas.drawCircle(const Offset(3, -12), 10, skin);
    canvas.restore();

    // Stethoscope
    canvas.drawArc(
      const Rect.fromLTWH(76, 103, 49, 49),
      0.2,
      math.pi - 0.4,
      false,
      line,
    );
    canvas.drawLine(const Offset(100, 126), const Offset(100, 145), line);
    canvas.drawCircle(
      const Offset(100, 148),
      5,
      Paint()..color = const Color(0xFF8A79B8),
    );

    // Face
    canvas.drawOval(const Rect.fromLTWH(70, 25, 60, 65), skin);

    // Ears
    canvas.drawOval(const Rect.fromLTWH(65, 49, 12, 19), skin);
    canvas.drawOval(const Rect.fromLTWH(123, 49, 12, 19), skin);

    // Hair
    final hair = Paint()..color = const Color(0xFF493B38);
    final hairPath = Path()
      ..moveTo(70, 57)
      ..quadraticBezierTo(63, 14, 101, 16)
      ..quadraticBezierTo(139, 16, 131, 58)
      ..lineTo(121, 43)
      ..quadraticBezierTo(99, 54, 79, 40)
      ..close();
    canvas.drawPath(hairPath, hair);

    // Nurse cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 12, 49, 23),
        const Radius.circular(8),
      ),
      white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(96, 17, 8, 14),
      Paint()..color = const Color(0xFFE66D76),
    );
    canvas.drawRect(
      const Rect.fromLTWH(93, 20, 14, 8),
      Paint()..color = const Color(0xFFE66D76),
    );

    // Eyes
    final eyes = Paint()..color = const Color(0xFF493B38);
    canvas.drawCircle(const Offset(89, 60), 2.4, eyes);
    canvas.drawCircle(const Offset(112, 60), 2.4, eyes);

    // Smile
    canvas.drawArc(
      const Rect.fromLTWH(91, 62, 20, 13),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFFB96562)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cheeks
    final blush = Paint()..color = const Color(0x30E98282);
    canvas.drawCircle(const Offset(81, 69), 5, blush);
    canvas.drawCircle(const Offset(120, 69), 5, blush);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NursePainter oldDelegate) {
    return oldDelegate.wave != wave;
  }
}
