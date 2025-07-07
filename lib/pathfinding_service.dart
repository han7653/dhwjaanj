import 'dart:collection';
import 'navigation_data.dart'; // NavNode, WeightedEdge 클래스를 사용하기 위함

// 다익스트라 알고리즘을 실행하는 서비스 클래스
class PathfindingService {
  
  // 가중치 기반의 최단 경로를 찾아주는 핵심 함수
  List<String> findShortestPath({
    required String startId,
    required String endId,
    required Map<String, List<WeightedEdge>> graph,
  }) {
    // 1. 초기화 작업
    final distances = <String, double>{};
    final previousNodes = <String, String?>{}; // 경로 역추적을 위한 맵
    final priorityQueue = PriorityQueue<MapEntry<String, double>>(
      (a, b) => a.value.compareTo(b.value),
    );

    // 모든 노드의 거리를 무한대로 초기화
    for (var nodeId in graph.keys) {
      distances[nodeId] = double.infinity;
      previousNodes[nodeId] = null;
    }

    // 출발점 설정
    distances[startId] = 0;
    priorityQueue.add(MapEntry(startId, 0));

    // 2. 최단 경로 탐색
    while (priorityQueue.isNotEmpty) {
      final currentNodeId = priorityQueue.removeFirst().key;
      
      if (currentNodeId == endId) break;

      // 현재 노드와 연결된 이웃들을 확인
      for (var edge in graph[currentNodeId] ?? []) {
        final neighborId = edge.nodeId;
        final newDistance = distances[currentNodeId]! + edge.weight;
        
        // 더 짧은 경로를 발견하면 정보 업데이트
        if (newDistance < (distances[neighborId] ?? double.infinity)) {
          distances[neighborId] = newDistance;
          
          // ★★★★★ 여기가 바로 버그의 원인이었습니다! ★★★★★
          // 이웃 노드의 이전 노드는 '현재 노드'가 되어야 합니다.
          // 제가 실수로 이웃 노드 자신을 가리키도록 잘못 작성했습니다.
          previousNodes[neighborId] = currentNodeId; // <--- 이렇게 수정!

          priorityQueue.add(MapEntry(neighborId, newDistance));
        }
      }
    }

    // 3. 경로 역추적
    final path = <String>[];
    String? currentNode = endId;
    while (currentNode != null) {
      path.add(currentNode);
      currentNode = previousNodes[currentNode];
    }
    
    // 경로가 출발지 -> 도착지 순서가 되도록 뒤집어서 반환
    if (path.length > 1 && path.last == startId) {
      return path.reversed.toList();
    } else {
      // 경로를 찾지 못한 경우 빈 리스트 반환
      return [];
    }
  }
}

// 다익스트라 알고리즘을 위한 우선순위 큐(Priority Queue) 구현체
class PriorityQueue<E> {
  final List<E> _elements = [];
  final int Function(E, E) _comparator;

  PriorityQueue(this._comparator);

  bool get isNotEmpty => _elements.isNotEmpty;

  void add(E element) {
    _elements.add(element);
    _elements.sort(_comparator);
  }

  E removeFirst() {
    return _elements.removeAt(0);
  }
}
