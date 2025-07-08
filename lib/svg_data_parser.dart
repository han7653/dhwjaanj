// lib/svg_data_parser.dart

import 'package:xml/xml.dart';
import 'package:flutter/material.dart';
import 'navigation_data.dart';

class SvgDataParser {
  // SVG 텍스트 내용을 직접 받아 버튼(강의실) 정보를 파싱합니다.
  static List<Map<String, dynamic>> parseButtonData(String svgContent) {
    final document = XmlDocument.parse(svgContent);
    final clickableGroups = document.findAllElements('g').where(
      (node) => node.getAttribute('id') == 'Clickable_Rooms',
    );
    if (clickableGroups.isEmpty) return [];

    final List<Map<String, dynamic>> buttonList = [];
    final clickableGroup = clickableGroups.first;

    // 사각형(rect) 모양의 버튼 파싱
    clickableGroup.findElements('rect').forEach((rect) {
      buttonList.add({
        'id': rect.getAttribute('id') ?? '',
        'x': double.tryParse(rect.getAttribute('x') ?? '0.0') ?? 0.0,
        'y': double.tryParse(rect.getAttribute('y') ?? '0.0') ?? 0.0,
        'width': double.tryParse(rect.getAttribute('width') ?? '0.0') ?? 0.0,
        'height': double.tryParse(rect.getAttribute('height') ?? '0.0') ?? 0.0,
      });
    });

    // 비정형(path) 모양의 버튼 파싱
    clickableGroup.findElements('path').forEach((path) {
      buttonList.add({
        'id': path.getAttribute('id') ?? '',
        'path': path.getAttribute('d') ?? '',
      });
    });
    return buttonList;
  }

  // SVG 텍스트 내용을 직접 받아 길찾기 노드 정보를 파싱합니다.
  static Map<String, NavNode> parseNavigationNodes(String svgContent) {
    final document = XmlDocument.parse(svgContent);
    final navGroups = document.findAllElements('g').where(
      (node) => node.getAttribute('id') == 'Navigation_Nodes',
    );
    if (navGroups.isEmpty) return {};

    final Map<String, NavNode> nodeMap = {};
    final navGroup = navGroups.first;

    // 원(circle) 또는 타원(ellipse) 모양의 노드 파싱
    final elements = [...navGroup.findElements('circle'), ...navGroup.findElements('ellipse')];
    for (var element in elements) {
      final id = element.getAttribute('id');
      final cx = double.tryParse(element.getAttribute('cx') ?? '0.0') ?? 0.0;
      final cy = double.tryParse(element.getAttribute('cy') ?? '0.0') ?? 0.0;
      if (id != null) {
        nodeMap[id] = NavNode(id: id, position: Offset(cx, cy));
      }
    }
    return nodeMap;
  }
}
