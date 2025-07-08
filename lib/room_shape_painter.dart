// lib/room_shape_painter.dart (수정된 전체 코드)

import 'package:flutter/material.dart';

class RoomShapePainter extends CustomPainter {
  final bool isSelected;

  RoomShapePainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (isSelected) {
      // 선택된 강의실은 파란색 반투명으로 하이라이트합니다.
      paint.color = Colors.blue.withOpacity(0.5);
    } else {
      // 선택되지 않은 강의실은 사용자가 탭할 수 있도록 영역만 차지하고 색상은 투명하게 처리합니다.
      // 디버깅 시에는 Colors.grey.withOpacity(0.2) 등으로 색을 지정해 영역을 확인할 수 있습니다.
      paint.color = Colors.transparent;
    }

    // 이 Painter가 그려지는 전체 영역에 사각형을 그립니다.
    // 영역의 크기와 위치는 building_map_page.dart의 Positioned.fromRect가 결정합니다.
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant RoomShapePainter oldDelegate) {
    // isSelected 상태가 변경될 때만 다시 그리도록 최적화합니다.
    return oldDelegate.isSelected != isSelected;
  }
}
