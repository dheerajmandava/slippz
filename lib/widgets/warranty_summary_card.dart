import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:sizer/sizer.dart';

class WarrantySummaryCard extends StatelessWidget {
  final double coveredValue;
  final double expiringValue;
  final double totalValue;

  const WarrantySummaryCard({
    super.key,
    required this.coveredValue,
    required this.expiringValue,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty state
    if (totalValue == 0) {
      return Container(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              'No warranties yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                fontFamily: 'Arial',
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Add your first receipt to get started',
              style: TextStyle(
                fontSize: 10.sp,
                color: Color(0xFF9CA3AF),
                fontFamily: 'Arial',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return Container(
      padding:  EdgeInsets.all(2.w),
      child: Column(
        children: [
          // Hand-drawn donut chart with legends
          SizedBox(
            height: 15.h,
            child: CustomPaint(
              size: Size(100.w, 25.h),
              painter: HandDrawnDonutChartPainter(
                coveredValue: coveredValue,
                expiringValue: expiringValue,
                totalValue: totalValue,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          
          Column(
            children: [
              Text(
                '\$${totalValue.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                )}',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.5,
                  
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Total Value',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HandDrawnDonutChartPainter extends CustomPainter {
  final double coveredValue;
  final double expiringValue;
  final double totalValue;

  HandDrawnDonutChartPainter({
    required this.coveredValue,
    required this.expiringValue,
    required this.totalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Donut chart positioning
    final donutCenter = Offset(size.width / 2, size.height * 0.45);
    final donutRadius = size.width * 0.25; // Slightly smaller for better proportions
    final strokeWidth = size.width * 0.08;

    // Draw the hand-drawn donut chart
    _drawHandDrawnDonutChart(canvas, donutCenter, donutRadius, strokeWidth);
    
    // Draw legends with hand-drawn lines
    _drawHandDrawnLegends(canvas, size, donutCenter, donutRadius, strokeWidth);
  }

  Path _createHandDrawnCircle(Offset center, double radius, {int points = 80, double wobble = 1.5}) {
    final path = Path();
    final random = math.Random(42); // Fixed seed for consistent randomness
    
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final wobbleAmount = wobble * (0.7 + random.nextDouble() * 0.3);
      final r = radius + (random.nextDouble() - 0.5) * wobbleAmount;
      
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Add some curve variation for hand-drawn feel
        final prevAngle = ((i - 1) / points) * 2 * math.pi;
        final prevR = radius + (random.nextDouble() - 0.5) * wobbleAmount;
        final prevX = center.dx + prevR * math.cos(prevAngle);
        final prevY = center.dy + prevR * math.sin(prevAngle);
        
        final cp1X = prevX + (x - prevX) * 0.4 + (random.nextDouble() - 0.5) * wobble * 0.5;
        final cp1Y = prevY + (y - prevY) * 0.4 + (random.nextDouble() - 0.5) * wobble * 0.5;
        final cp2X = prevX + (x - prevX) * 0.6 + (random.nextDouble() - 0.5) * wobble * 0.5;
        final cp2Y = prevY + (y - prevY) * 0.6 + (random.nextDouble() - 0.5) * wobble * 0.5;
        
        path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, x, y);
      }
    }
    
    path.close();
    return path;
  }

  void _drawHandDrawnDonutChart(Canvas canvas, Offset center, double radius, double strokeWidth) {
    // Calculate total for segments (covered + expiring)
    final segmentTotal = coveredValue + expiringValue;
    
    if (segmentTotal == 0) {
      // Empty donut with hand-drawn effect
      final paint = Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final outerPath = _createHandDrawnCircle(center, radius + strokeWidth / 2, wobble: 2.0);
      final innerPath = _createHandDrawnCircle(center, radius - strokeWidth / 2, wobble: 1.5);
      
      canvas.drawPath(outerPath, paint);
      
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(outerPath, outlinePaint);
      canvas.drawPath(innerPath, outlinePaint);
      return;
    }
    
    // Calculate angles for segments
    final coveredAngle = (coveredValue / segmentTotal) * 2 * math.pi;
    final expiringAngle = (expiringValue / segmentTotal) * 2 * math.pi;
    final startAngle = -math.pi / 2; // Start from top

    // Draw covered segment (teal) as filled area between two circles
    if (coveredAngle > 0) {
      final coveredPaint = Paint()
        ..color = const Color(0xFF14B8A6)
        ..style = PaintingStyle.fill;
      
      final segmentPath = _createSegmentPath(center, radius, strokeWidth, startAngle, coveredAngle);
      canvas.drawPath(segmentPath, coveredPaint);
    }
    
    // Draw expiring segment (yellow/amber) as filled area
    if (expiringAngle > 0) {
      final expiringPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      
      final segmentPath = _createSegmentPath(center, radius, strokeWidth, startAngle + coveredAngle, expiringAngle);
      canvas.drawPath(segmentPath, expiringPaint);
    }
    
    // Draw hand-drawn black outlines
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    
    final outerOutline = _createHandDrawnCircle(center, radius + strokeWidth / 2, wobble: 1.0);
    final innerOutline = _createHandDrawnCircle(center, radius - strokeWidth / 2, wobble: 0.8);
    
    canvas.drawPath(outerOutline, outlinePaint);
    canvas.drawPath(innerOutline, outlinePaint);
    
    // Draw segment divider lines if both segments exist
    if (coveredAngle > 0 && expiringAngle > 0) {
      _drawSegmentDivider(canvas, center, radius, strokeWidth, startAngle + coveredAngle, outlinePaint);
    }
  }

  Path _createSegmentPath(Offset center, double radius, double strokeWidth, double startAngle, double sweepAngle) {
    final path = Path();
    final outerRadius = radius + strokeWidth / 2;
    final innerRadius = radius - strokeWidth / 2;
    
    // Create outer arc
    final outerArc = _createHandDrawnArc(center, outerRadius, startAngle, sweepAngle);
    
    // Create inner arc (reversed direction)
    final innerArc = _createHandDrawnArc(center, innerRadius, startAngle + sweepAngle, -sweepAngle);
    
    // Connect them to form a filled segment
    path.addPath(outerArc, Offset.zero);
    
    // Connect end of outer arc to start of inner arc
    final endAngle = startAngle + sweepAngle;
    final outerEndX = center.dx + outerRadius * math.cos(endAngle);
    final outerEndY = center.dy + outerRadius * math.sin(endAngle);
    final innerEndX = center.dx + innerRadius * math.cos(endAngle);
    final innerEndY = center.dy + innerRadius * math.sin(endAngle);
    
    path.lineTo(innerEndX, innerEndY);
    path.addPath(innerArc, Offset.zero);
    
    // Connect back to start
    final innerStartX = center.dx + innerRadius * math.cos(startAngle);
    final innerStartY = center.dy + innerRadius * math.sin(startAngle);
    final outerStartX = center.dx + outerRadius * math.cos(startAngle);
    final outerStartY = center.dy + outerRadius * math.sin(startAngle);
    
    path.lineTo(outerStartX, outerStartY);
    path.close();
    
    return path;
  }

  Path _createHandDrawnArc(Offset center, double radius, double startAngle, double sweepAngle) {
    final path = Path();
    final random = math.Random(42 + (startAngle * 100).toInt());
    final points = (sweepAngle.abs() * 30 / math.pi).toInt().clamp(15, 60);
    
    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final angle = startAngle + sweepAngle * t;
      final wobbleAmount = 1.0 * (0.8 + random.nextDouble() * 0.4);
      final r = radius + (random.nextDouble() - 0.5) * wobbleAmount;
      
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    return path;
  }

  void _drawSegmentDivider(Canvas canvas, Offset center, double radius, double strokeWidth, double angle, Paint paint) {
    final random = math.Random(99);
    
    // Outer point with slight wobble
    final outerWobble = 1.0 * (random.nextDouble() - 0.5);
    final outerPoint = Offset(
      center.dx + (radius + strokeWidth / 2 + outerWobble) * math.cos(angle),
      center.dy + (radius + strokeWidth / 2 + outerWobble) * math.sin(angle),
    );
    
    // Inner point with slight wobble
    final innerWobble = 0.8 * (random.nextDouble() - 0.5);
    final innerPoint = Offset(
      center.dx + (radius - strokeWidth / 2 + innerWobble) * math.cos(angle),
      center.dy + (radius - strokeWidth / 2 + innerWobble) * math.sin(angle),
    );
    
    canvas.drawLine(innerPoint, outerPoint, paint);
  }

  Path _createOutwardConnectorLine(Offset textPoint, Offset donutPoint) {
    final path = Path();
    final random = math.Random((textPoint.dx * 100 + textPoint.dy * 100).toInt());
    
    // Start from text
    path.moveTo(
      textPoint.dx + (random.nextDouble() - 0.5) * 1, 
      textPoint.dy + (random.nextDouble() - 0.5) * 1
    );
    
    // Create a simple curved line from text to donut edge
    // Add some hand-drawn wobble using screen percentage values
    final midX = (textPoint.dx + donutPoint.dx) / 2 + (random.nextDouble() - 0.5) * 15;
    final midY = (textPoint.dy + donutPoint.dy) / 2 + (random.nextDouble() - 0.5) * 10;
    
    // Create curved connector with hand-drawn feel
    path.quadraticBezierTo(
      midX, 
      midY, 
      donutPoint.dx + (random.nextDouble() - 0.5) * 2, 
      donutPoint.dy + (random.nextDouble() - 0.5) * 2
    );
    
    return path;
  }
void _drawHandDrawnLegends(
  Canvas canvas,
  Size size,
  Offset donutCenter,
  double donutRadius,
  double strokeWidth,
) {
  final total = coveredValue + expiringValue;
  if (total == 0) return;

  final coveredAngle = (coveredValue / total) * 2 * math.pi;
  final expiringAngle = (expiringValue / total) * 2 * math.pi;
  final startAngle = -math.pi / 2; // top

  final linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final textStyle = TextStyle(
    fontSize: size.width * 0.035,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    fontFamily: 'Arial',
  );


  void drawLegend({
    required String text,
    required double midAngle,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    // 1.  donut edge point (outer rim)
    final donutEdge = Offset(
      donutCenter.dx + (donutRadius + strokeWidth / 2) * math.cos(midAngle),
      donutCenter.dy + (donutRadius + strokeWidth / 2) * math.sin(midAngle),
    );

    // 2.  text anchor point – push it further outside
    const labelRadiusFactor = 1.55; // bigger => further outside
    final textCenter = Offset(
      donutCenter.dx + (donutRadius * labelRadiusFactor) * math.cos(midAngle),
      donutCenter.dy + (donutRadius * labelRadiusFactor) * math.sin(midAngle),
    );

    // 3.  text top-left offset for painting
    final textOffset = align == TextAlign.left
        ? textCenter - Offset(0, painter.height / 2)
        : textCenter - Offset(painter.width, painter.height / 2);

    // 4.  paint text
    painter.paint(canvas, textOffset);

    // 5.  paint connector – from donut edge to text edge facing the donut
    final textEdge = align == TextAlign.left
        ? textOffset + Offset(0, painter.height / 2) // left edge
        : textOffset + Offset(painter.width, painter.height / 2); // right edge

    canvas.drawPath(
      _createOutwardConnectorLine(donutEdge, textEdge),
      linePaint,
    );
  }

  /* -------------------------------------------------
   *  Covered label – at teal segment
   * ------------------------------------------------- */
  if (coveredValue > 0) {
    final midAngle = startAngle + coveredAngle / 2;
    drawLegend(
      text: '\$${coveredValue.toStringAsFixed(0)} Covered',
      midAngle: midAngle,
      align: midAngle.abs() < math.pi / 2 ? TextAlign.left : TextAlign.right,
    );
  }

  /* -------------------------------------------------
   *  Expiring label – at yellow segment
   * ------------------------------------------------- */
  if (expiringValue > 0) {
    final midAngle = startAngle + coveredAngle + expiringAngle / 2;
    drawLegend(
      text: 'expiring soon\n(\$${expiringValue.toStringAsFixed(0)})',
      midAngle: midAngle,
      align: midAngle.abs() < math.pi / 2 ? TextAlign.left : TextAlign.right,
    );
  }
}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HandDrawnDonutChartPainter &&
        (oldDelegate.coveredValue != coveredValue ||
         oldDelegate.expiringValue != expiringValue ||
         oldDelegate.totalValue != totalValue);
  }
}