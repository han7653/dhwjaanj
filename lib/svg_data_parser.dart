import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';
import 'navigation_data.dart'; // NavNode 클래스를 사용하기 위함

class SvgDataParser {
  // SVG 파일에서 버튼 정보를 파싱하는 함수 (수정 필요 없음)
  static Future<List<Map<String, dynamic>>> parseButtonData(String assetPath) async {
    try {
      final svgString = await rootBundle.loadString(assetPath);
      final document = XmlDocument.parse(svgString);

      final clickableGroups = document.findAllElements('g').where(
            (node) => node.getAttribute('id') == 'Clickable_Rooms',
          );

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
          'height': double.tryParse(rect.getAttribute('height') ?? '0.0') ?? 0.0,
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
      print('SVG 버튼 데이터 파싱 중 오류 발생 ($assetPath): $e');
      return [];
    }
  }

  // SVG 파일에서 길찾기 노드 정보를 파싱하는 함수
  // <circle>과 <ellipse> 태그 모두를 찾아서 노드 좌표로 사용합니다.
  static Future<Map<String, NavNode>> parseNavigationNodes(String assetPath) async {
    try {
      final svgString = await rootBundle.loadString(assetPath);
      final document = XmlDocument.parse(svgString);
      
      final navGroups = document.findAllElements('g').where(
            (node) => node.getAttribute('id') == 'Navigation_Nodes',
          );
      
      if (navGroups.isEmpty) {
        print('경고: $assetPath 파일에 "Navigation_Nodes" 레이어가 없습니다.');
        return {};
      }

      final navGroup = navGroups.first;
      final Map<String, NavNode> nodeMap = {};

      // 1. <circle> 태그를 모두 찾아서 추가합니다.
      navGroup.findElements('circle').forEach((circle) {
        final id = circle.getAttribute('id');
        final cx = double.tryParse(circle.getAttribute('cx') ?? '0.0') ?? 0.0;
        final cy = double.tryParse(circle.getAttribute('cy') ?? '0.0') ?? 0.0;

        if (id != null) {
          nodeMap[id] = NavNode(id: id, position: Offset(cx, cy));
        }
      });

      // 2. <ellipse> 태그도 모두 찾아서 추가합니다.
      // 이렇게 하면 원이든 타원이든 모두 길찾기 노드로 인식할 수 있습니다.
      navGroup.findElements('ellipse').forEach((ellipse) {
        final id = ellipse.getAttribute('id');
        final cx = double.tryParse(ellipse.getAttribute('cx') ?? '0.0') ?? 0.0;
        final cy = double.tryParse(ellipse.getAttribute('cy') ?? '0.0') ?? 0.0;
        
        if (id != null) {
          nodeMap[id] = NavNode(id: id, position: Offset(cx, cy));
        }
      });

      return nodeMap;
    } catch (e) {
      print('SVG 노드 데이터 파싱 중 오류 발생 ($assetPath): $e');
      return {};
    }
  }
}
