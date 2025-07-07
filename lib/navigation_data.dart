// lib/navigation_data.dart

import 'package:flutter/material.dart';

// 각 노드의 ID와 좌표를 저장하는 클래스
class NavNode {
  final String id;
  final Offset position; // x, y 좌표를 Offset으로 관리

  NavNode({required this.id, required this.position});
}

// 모든 길찾기 노드의 정보를 정의합니다.
// SVG 파일의 'Navigation_Nodes' 레이어에서 좌표를 추출했습니다.
final Map<String, NavNode> allNavNodes = {
  "101": NavNode(id: "101", position: const Offset(49.342125, 66.342125)),
  "102": NavNode(id: "102", position: const Offset(106.84212, 66.342125)),
  "103": NavNode(id: "103", position: const Offset(148.34213, 66.342125)),
  "104": NavNode(id: "104", position: const Offset(181.49866, 73.68399)),
  "105": NavNode(id: "105", position: const Offset(182.28923, 107.34212)),
  "106": NavNode(id: "106", position: const Offset(160.58905, 107.34212)),
  "107": NavNode(id: "107", position: const Offset(166.64838, 171.67546)),
  "108": NavNode(id: "108", position: const Offset(183.8463, 187.55046)),
  "109": NavNode(id: "109", position: const Offset(184.90463, 208.9817)),
  "110": NavNode(id: "110", position: const Offset(137.80879, 220.3588)),
  "111": NavNode(id: "111", position: const Offset(90.1838, 219.03587)),
  "112": NavNode(id: "112", position: const Offset(30.652548, 198.34213)),
  "b1": NavNode(id: "b1", position: const Offset(49.342125, 86.842125)),
  "b2": NavNode(id: "b2", position: const Offset(106.84212, 86.842125)),
  "b3": NavNode(id: "b3", position: const Offset(148.34213, 86.842125)),
  "b4": NavNode(id: "b4", position: const Offset(49.342125, 113.99628)),
  "b5": NavNode(id: "b5", position: const Offset(49.342125, 150.84213)),
  "b6": NavNode(id: "b6", position: const Offset(49.342125, 198.34213)),
  "b7": NavNode(id: "b7", position: const Offset(89.390045, 198.34213)),
  "b8": NavNode(id: "b8", position: const Offset(138.07338, 198.34213)),
  "b9": NavNode(id: "b9", position: const Offset(167.17755, 198.34213)),
  "b10": NavNode(id: "b10", position: const Offset(62.66713, 113.99628)),
  "b11": NavNode(id: "b11", position: const Offset(61.342129, 150.84213)),
  "indoor-left-stairs": NavNode(
    id: "indoor-left-stairs",
    position: const Offset(61.342129, 133.84004),
  ),
  "indoor-right-stairs": NavNode(
    id: "indoor-right-stairs",
    position: const Offset(61.342125, 174.0567),
  ),
  "outdoor-left-stairs": NavNode(
    id: "outdoor-left-stairs",
    position: const Offset(145.34213, 122.99213),
  ),
  "outdoor-right-stairs": NavNode(
    id: "outdoor-right-stairs",
    position: const Offset(145.34213, 165.85463),
  ),
  "enterence": NavNode(
    id: "enterence",
    position: const Offset(145.34213, 144.84213),
  ),
};

// 노드들이 어떻게 연결되어 있는지 정의합니다. (인접 리스트 방식)
// 각 노드와 직접 연결된 이웃 노드들의 ID 리스트입니다.
final Map<String, List<String>> adjacencyList = {
  // 강의실 <-> 복도 연결
  "101": ["b1"], "b1": ["101", "b2", "b4"],
  "102": ["b2"], "b2": ["b1", "b2"],
  "103": ["b3"], "b3": ["b2", "104", "enterence"],
  "104": ["b3"],
  "105": ["b9"],
  "106": ["b9"],
  "107": ["b9"],
  "108": ["b9"],
  "109": ["b8"],
  "110": ["b8"],
  "111": ["b7"],
  "112": ["b6"],

  // 복도 노드 간 연결
  "b4": ["b1", "b5", "b10"],
  "b5": ["b4", "b6", "b11"],
  "b6": ["b5", "b7", "112"],
  "b7": ["b6", "b8", "111"],
  "b8": ["b7", "b9", "109", "110"],
  "b9": ["b8", "105", "106", "107", "108"],
  "b10": ["b4", "indoor-left-stairs"],
  "b11": ["b5", "indoor-left-stairs", "indoor-right-stairs"],

  // 계단 및 입구 연결
  "indoor-left-stairs": ["b10", "b11"],
  "indoor-right-stairs": ["b11"],
  "enterence": ["b3", "outdoor-left-stairs", "outdoor-right-stairs"],
  "outdoor-left-stairs": ["enterence"],
  "outdoor-right-stairs": ["enterence"],
};
