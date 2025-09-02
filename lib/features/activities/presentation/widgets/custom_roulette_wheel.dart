import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomRouletteWheel extends StatefulWidget {
  final List<WheelSlice> slices;
  final double size;
  final VoidCallback? onSpinComplete;
  final Stream<int>? selectedStream;

  const CustomRouletteWheel({
    super.key,
    required this.slices,
    this.size = 300,
    this.onSpinComplete,
    this.selectedStream,
  });

  @override
  State<CustomRouletteWheel> createState() => _CustomRouletteWheelState();
}

class _CustomRouletteWheelState extends State<CustomRouletteWheel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  double _currentRotation = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSpinComplete?.call();
      }
    });

    widget.selectedStream?.listen((selectedIndex) {
      _selectedIndex = selectedIndex;
      _spinToIndex(selectedIndex);
    });
  }

  void _spinToIndex(int index) {
    final double sliceAngle = 2 * math.pi / widget.slices.length;
    final double targetAngle = index * sliceAngle;
    
    // Add multiple rotations for effect (3-5 full rotations)
    final double fullRotations = 3 + math.Random().nextDouble() * 2;
    final double totalRotation = fullRotations * 2 * math.pi + targetAngle;
    
    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + totalRotation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _currentRotation += totalRotation;
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wheel
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: WheelPainter(slices: widget.slices),
                ),
              );
            },
          ),
          // Pointer/Indicator
          Positioned(
            top: 0,
            child: Container(
              width: 0,
              height: 0,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(width: 15, color: Colors.transparent),
                  right: BorderSide(width: 15, color: Colors.transparent),
                  bottom: BorderSide(width: 30, color: Colors.orange),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WheelSlice {
  final Color color;
  final String text;
  final Color textColor;
  final Color borderColor;

  const WheelSlice({
    required this.color,
    required this.text,
    this.textColor = Colors.white,
    this.borderColor = Colors.black,
  });
}

class WheelPainter extends CustomPainter {
  final List<WheelSlice> slices;

  WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * math.pi / slices.length;

    // Draw wheel slices
    for (int i = 0; i < slices.length; i++) {
      final startAngle = i * sliceAngle - math.pi / 2; // Start from top
      final slice = slices[i];

      // Draw slice
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = slice.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Draw text on outer rim
      _drawTextOnRim(
        canvas,
        slice.text,
        center,
        radius,
        startAngle + sliceAngle / 2,
        slice.textColor,
      );
    }

    // Draw outer border
    final outerBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, outerBorderPaint);
  }

  void _drawTextOnRim(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angle,
    Color textColor,
  ) {
    // Position text closer to the rim
    final textRadius = radius * 0.8; // 80% of radius for better rim placement
    final textX = center.dx + textRadius * math.cos(angle);
    final textY = center.dy + textRadius * math.sin(angle);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Center the text at the calculated position
    final offset = Offset(
      textX - textPainter.width / 2,
      textY - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
