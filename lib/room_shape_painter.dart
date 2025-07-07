// lib/room_shape_painter.dart

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class RoomShapePainter extends CustomPainter {
  final String svgPathData;
  final Color color;
  final double scale; // <-- 1. 확대/축소 비율을 받을 변수 추가

  RoomShapePainter({
    required this.svgPathData,
    required this.color,
    this.scale = 1.0, // <-- 2. 생성자에서 scale 값을 받도록 수정 (기본값 1.0)
  });

  @override
  void paint(Canvas canvas, Size size) {
    // <-- 3. 그림을 그리기 전에 캔버스 자체를 scale 값만큼 확대/축소
    canvas.scale(scale);

    final path = parseSvgPathData(svgPathData);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool hitTest(Offset position) {
    final path = parseSvgPathData(svgPathData);
    // <-- 4. 클릭 좌표 역시 scale을 역으로 적용하여 정확한 위치를 판단
    // 예: 2배 확대된 그림에서 (100, 100)을 클릭했다면,
    // 원본 그림의 (50, 50) 위치에 해당하는지 확인해야 함
    final scaledPosition = position.scale(1 / scale, 1 / scale);
    return path.contains(scaledPosition);
  }

  @override
  bool shouldRepaint(RoomShapePainter oldDelegate) {
    return oldDelegate.svgPathData != svgPathData ||
        oldDelegate.color != color ||
        oldDelegate.scale != scale;
  }
}
