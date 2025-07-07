// lib/path_painter.dart
import 'package:flutter/material.dart';
import 'navigation_data.dart'; // NavNode 클래스를 사용하기 위함

class PathPainter extends CustomPainter {
  final List<String> pathNodeIds;      // 그려야 할 경로를 노드 ID 리스트로 받음
  final Map<String, NavNode> allNodes; // 모든 노드의 좌표 정보를 담은 맵
  final double scale;                  // 화면 크기에 맞는 스케일 값

  PathPainter({
    required this.pathNodeIds,
    required this.allNodes,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 경로가 2개 미만의 점으로 이루어져 있으면 선을 그릴 수 없으므로 종료
    if (pathNodeIds.length < 2) return;

    // 경로를 그릴 펜(Paint) 설정 (색상, 굵기 등)
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    // 실제로 선을 그릴 경로(Path) 객체 생성
    final path = Path();
    
    // 경로의 첫 번째 노드 좌표를 찾아 펜을 그 위치로 이동 (그림 시작점)
    // scale을 곱해 화면 크기에 맞게 좌표를 조정
    final startPoint = allNodes[pathNodeIds.first]!.position.scale(scale, scale);
    path.moveTo(startPoint.dx, startPoint.dy);

    // 나머지 노드들을 순서대로 선으로 연결
    for (int i = 1; i < pathNodeIds.length; i++) {
      final nextNodeId = pathNodeIds[i];
      final nextPoint = allNodes[nextNodeId]!.position.scale(scale, scale);
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }
    
    // 완성된 경로를 캔버스에 한 번에 그립니다.
    canvas.drawPath(path, paint);
  }

  // 경로 정보가 바뀔 때마다 다시 그리도록 설정
  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) => true;
}
