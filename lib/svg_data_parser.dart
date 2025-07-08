// lib/svg_data_parser.dart (수정된 전체 코드)

import 'dart:ui';
import 'package:xml/xml.dart';

class SvgDataParser {
  /// SVG 내용에서 'rect' 태그를 파싱하여 터치 가능한 버튼(강의실) 데이터를 추출합니다.
  static List<Map<String, dynamic>> parseButtonData(String svgContent) {
    final List<Map<String, dynamic>> buttons = [];
    final document = XmlDocument.parse(svgContent);

    final rects = document.findAllElements('rect');
    for (var rect in rects) {
      final id = rect.getAttribute('id');
      final x = double.tryParse(rect.getAttribute('x') ?? '');
      final y = double.tryParse(rect.getAttribute('y') ?? '');
      final width = double.tryParse(rect.getAttribute('width') ?? '');
      final height = double.tryParse(rect.getAttribute('height') ?? '');

      if (id != null && x != null && y != null && width != null && height != null) {
        // [핵심 수정] 숫자 ID 조건 제거. 이제 'R'로 시작하는 ID도 버튼으로 처리됩니다.
        // 예를 들어, 'R101'과 같은 ID가 room_info.dart에 정의된 강의실과 일치하면 버튼으로 추가됩니다.
        if (id.startsWith('R') || int.tryParse(id) != null) { // 필요에 따라 조건을 더 유연하게 조정 가능
            buttons.add({
            'id': id,
            'rect': Rect.fromLTWH(x, y, width, height),
          });
        }
      }
    }
    return buttons;
  }

  /// SVG 내용에서 길찾기 노드를 파싱하여 ID와 좌표(Offset)의 맵을 반환합니다.
  /// 더 이상 NavNode 클래스를 사용하지 않습니다.
  static Map<String, Offset> parseNavigationNodes(String svgContent) {
    final Map<String, Offset> nodes = {};
    final document = XmlDocument.parse(svgContent);

    // SVG에서 <path> 태그 중 id 속성이 있는 것들을 찾습니다.
    final paths = document.findAllElements('path');
    for (var path in paths) {
      final id = path.getAttribute('id');
      final d = path.getAttribute('d'); // 'd' 속성 (path data)

      // 길찾기 노드(id가 'b'로 시작) 또는 주요 지점(계단, 입구 등)인 경우
      if (id != null && d != null && (id.startsWith('b') || id.contains('-stairs') || id.contains('enterence'))) {
        
        // 'd' 속성에서 좌표를 추출합니다. 예: "M 123.45 678.90"
        final parts = d.replaceAll('M', '').trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final x = double.tryParse(parts[0]);
          final y = double.tryParse(parts[1]);

          if (x != null && y != null) {
            nodes[id] = Offset(x, y);
          }
        }
      }
    }
    return nodes;
  }
}
