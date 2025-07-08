// lib/path_painter.dart (수정된 코드)

import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final List<Offset> pathPoints; // 노드 ID 대신 좌표 리스트를 직접 받음
  final double scale;

  PathPainter({
    required this.pathPoints,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.length < 2) return;

    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // 좌표를 스케일에 맞게 변환하여 사용
    final startPoint = pathPoints.first.scale(scale, scale);
    path.moveTo(startPoint.dx, startPoint.dy);

    for (int i = 1; i < pathPoints.length; i++) {
      final nextPoint = pathPoints[i].scale(scale, scale);
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    // 경로 좌표나 스케일이 변경될 때만 다시 그림
    return oldDelegate.pathPoints != pathPoints || oldDelegate.scale != scale;
  }
}
