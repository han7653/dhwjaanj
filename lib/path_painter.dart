// lib/path_painter.dart
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;

  PathPainter({required this.startPoint, required this.endPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent // 경로 선 색상
      ..strokeWidth = 4.0         // 경로 선 두께
      ..strokeCap = StrokeCap.round; // 선 끝을 둥글게 처리

    // 시작점(startPoint)에서 끝점(endPoint)까지 선을 그립니다.
    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    // 시작점이나 끝점이 바뀌었을 때만 다시 그리도록 설정
    return oldDelegate.startPoint != startPoint || oldDelegate.endPoint != endPoint;
  }
}
