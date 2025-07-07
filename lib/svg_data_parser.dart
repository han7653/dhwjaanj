// lib/svg_data_parser.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';

class SvgDataParser {
  // SVG 파일에서 모든 버튼(rect와 path) 정보를 동적으로 파싱하는 함수
  static Future<List<Map<String, dynamic>>> parseButtonData(
    String assetPath,
  ) async {
    try {
      final svgString = await rootBundle.loadString(assetPath);
      final document = XmlDocument.parse(svgString);

      // 'Clickable_Rooms' 그룹이 있는지 확인
      final clickableGroups = document
          .findAllElements('g')
          .where((node) => node.getAttribute('id') == 'Clickable_Rooms');

      // 만약 해당 그룹이 존재하지 않으면, 오류 대신 빈 리스트를 반환
      if (clickableGroups.isEmpty) {
        print('경고: $assetPath 파일에 "Clickable_Rooms" 레이어가 없습니다.');
        return [];
      }

      final clickableGroup = clickableGroups.first;
      final List<Map<String, dynamic>> buttonList = [];

      // 사각형(rect) 버튼 파싱
      clickableGroup.findElements('rect').forEach((rect) {
        buttonList.add({
          'id': rect.getAttribute('id') ?? '',
          'x': double.tryParse(rect.getAttribute('x') ?? '0.0') ?? 0.0,
          'y': double.tryParse(rect.getAttribute('y') ?? '0.0') ?? 0.0,
          'width': double.tryParse(rect.getAttribute('width') ?? '0.0') ?? 0.0,
          'height':
              double.tryParse(rect.getAttribute('height') ?? '0.0') ?? 0.0,
        });
      });

      // 복잡한 모양(path) 버튼 파싱
      clickableGroup.findElements('path').forEach((path) {
        buttonList.add({
          'id': path.getAttribute('id') ?? '',
          'path': path.getAttribute('d') ?? '',
        });
      });

      return buttonList;
    } catch (e) {
      print('SVG 버튼 데이터 파싱 중 예상치 못한 오류 발생 ($assetPath): $e');
      return [];
    }
  }

  // SVG 파일에서 길찾기 노드 정보를 파싱하는 함수 (navigation_data.dart 대체 가능)
  static Future<Map<String, Offset>> parseNavigationNodes(
    String assetPath,
  ) async {
    try {
      final svgString = await rootBundle.loadString(assetPath);
      final document = XmlDocument.parse(svgString);

      // 'Navigation_Nodes' 그룹이 있는지 확인
      final navGroups = document
          .findAllElements('g')
          .where((node) => node.getAttribute('id') == 'Navigation_Nodes');

      // 만약 해당 그룹이 존재하지 않으면, 오류 대신 빈 맵을 반환
      if (navGroups.isEmpty) {
        print('경고: $assetPath 파일에 "Navigation_Nodes" 레이어가 없습니다.');
        return {};
      }

      final navGroup = navGroups.first;
      final Map<String, Offset> nodeMap = {};

      navGroup.findElements('circle').forEach((circle) {
        final id = circle.getAttribute('id');
        final cx = double.tryParse(circle.getAttribute('cx') ?? '0.0') ?? 0.0;
        final cy = double.tryParse(circle.getAttribute('cy') ?? '0.0') ?? 0.0;

        if (id != null) {
          nodeMap[id] = Offset(cx, cy);
        }
      });
      return nodeMap;
    } catch (e) {
      print('SVG 노드 데이터 파싱 중 예상치 못한 오류 발생 ($assetPath): $e');
      return {};
    }
  }
}
