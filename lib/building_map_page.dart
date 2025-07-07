// 필요한 패키지들을 불러옵니다.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'svg_data_parser.dart'; // SVG 파서
import 'room_info.dart'; // 강의실 정보
import 'room_info_sheet.dart'; // 하단 정보 시트
import 'room_shape_painter.dart'; // 버튼 페인터
import 'navigation_data.dart'; // 길찾기 '연결' 정보
import 'path_painter.dart'; // 수정된 경로 페인터
import 'pathfinding_service.dart'; // ★★★ 새로 만든 길찾기 서비스 ★★★

class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage({super.key});
  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --------------------------------------------------
  // 1. 상태 변수
  // --------------------------------------------------
  int selectedFloor = 1;
  String? selectedRoomId;
  String? startNodeId;
  String? endNodeId;

  List<Map<String, dynamic>> _buttonData = [];
  Map<String, NavNode> _navNodes = {};
  List<String> _shortestPath = []; // ★★★ 계산된 최단 경로를 저장할 리스트 ★★★

  bool _isLoading = true;
  final List<int> floors = [1, 2, 3];
  final TransformationController _transformationController =
      TransformationController();
  Timer? _resetTimer;
  static const double svgScale = 0.7;

  // --- 길찾기 서비스 인스턴스 ---
  final PathfindingService _pathfindingService = PathfindingService();

  // --- Getter ---
  String get svgAsset => 'assets/w19_$selectedFloor.svg';
  Map<String, List<String>> get currentAdjacencyList {
    switch (selectedFloor) {
      case 1:
        return floor3AdjacencyList;
      case 2:
        return floor5AdjacencyList;
      default:
        return {};
    }
  }

  // --------------------------------------------------
  // 2. 생명주기 및 데이터 로딩
  // --------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadFloorData(selectedFloor);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadFloorData(int floor) async {
    setState(() => _isLoading = true);
    final assetPath = 'assets/w19_$floor.svg';
    final buttons = await SvgDataParser.parseButtonData(assetPath);
    final nodes = await SvgDataParser.parseNavigationNodes(assetPath);
    if (mounted) {
      setState(() {
        _buttonData = buttons;
        _navNodes = nodes;
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------
  // 3. 핵심 로직: 길찾기 실행 및 보조 함수
  // --------------------------------------------------

  // ★★★ 최단 경로를 계산하고 화면을 다시 그리도록 요청하는 함수 ★★★
  void _findAndDrawPath() {
    // 출발지와 도착지가 모두 선택되었는지, 그리고 좌표 정보가 있는지 확인
    if (startNodeId == null || endNodeId == null || _navNodes.isEmpty) {
      return;
    }

    // 1. 현재 층의 연결 정보를 기반으로 '가중치 그래프'를 동적으로 생성합니다.
    final graph = _createWeightedGraph(_navNodes, currentAdjacencyList);

    // 2. 다익스트라 알고리즘을 실행하여 최단 경로(노드 ID 리스트)를 얻습니다.
    final path = _pathfindingService.findShortestPath(
      startId: startNodeId!,
      endId: endNodeId!,
      graph: graph,
    );

    // 3. 계산된 경로를 상태 변수에 저장하고, 화면을 다시 그리도록 요청(setState)합니다.
    setState(() {
      _shortestPath = path;
    });
  }

  // ★★★ 연결 정보와 좌표 정보를 합쳐 가중치 그래프를 만드는 보조 함수 ★★★
  Map<String, List<WeightedEdge>> _createWeightedGraph(
      Map<String, NavNode> nodes, Map<String, List<String>> adjacencyList) {
    final graph = <String, List<WeightedEdge>>{};
    adjacencyList.forEach((nodeId, neighbors) {
      final startNode = nodes[nodeId];
      if (startNode == null) return;

      graph[nodeId] = [];
      for (var neighborId in neighbors) {
        final endNode = nodes[neighborId];
        if (endNode != null) {
          final distance = (endNode.position - startNode.position).distance;
          graph[nodeId]!
              .add(WeightedEdge(nodeId: neighborId, weight: distance));
        } else {
          // ★★★ 바로 여기에 디버깅 코드를 추가합니다! ★★★
          print('--- 데이터 불일치 경고 ---');
          print('연결 정보(adjacencyList)에는 있는데, SVG 파일에 없는 노드 ID를 발견했습니다.');
          print('연결 시작점: $nodeId');
          print('찾을 수 없는 이웃 노드: $neighborId');
          print('--------------------------');
        }
      }
    });
    return graph;
  }

  // --------------------------------------------------
  // 4. 이벤트 핸들러
  // --------------------------------------------------
  void _onFloorChanged(int newFloor) {
    setState(() {
      selectedFloor = newFloor;
      selectedRoomId = null;
      startNodeId = null;
      endNodeId = null;
      _shortestPath = []; // 층을 바꾸면 경로 초기화
      _loadFloorData(newFloor);
    });
  }

  void _showRoomInfoSheet(BuildContext context, String id) async {
    final roomInfo = roomInfos[id];
    if (roomInfo == null) {
      print('정보를 찾을 수 없습니다: $id');
      return;
    }

    setState(() => selectedRoomId = id);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomInfoSheet(
        roomInfo: roomInfo,
        onDeparture: () {
          setState(() {
            startNodeId = id.startsWith('R') ? id.substring(1) : id;
            _findAndDrawPath(); // ★★★ 출발지 설정 후 길찾기 실행 ★★★
          });
          Navigator.pop(context);
        },
        onArrival: () {
          setState(() {
            endNodeId = id.startsWith('R') ? id.substring(1) : id;
            _findAndDrawPath(); // ★★★ 도착지 설정 후 길찾기 실행 ★★★
          });
          Navigator.pop(context);
        },
      ),
    );
    if (mounted) setState(() => selectedRoomId = null);
  }

  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      _transformationController.value = Matrix4.identity();
    });
  }

  // --------------------------------------------------
  // 5. UI 빌드
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const double svgWidth = 210, svgHeight = 297;
    return Scaffold(
      appBar: AppBar(title: const Text('강의실 안내도')),
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final scaleX = constraints.maxWidth / svgWidth;
            final scaleY = constraints.maxHeight / svgHeight;
            final baseScale = scaleX < scaleY ? scaleX : scaleY;
            final totalScale = baseScale * 1.0;
            final double svgDisplayWidth = svgWidth * totalScale * svgScale;
            final double svgDisplayHeight = svgHeight * totalScale * svgScale;
            final double leftOffset =
                (svgWidth * totalScale - svgDisplayWidth) / 2;
            final double topOffset =
                (svgHeight * totalScale - svgDisplayHeight) / 2;

            if (_isLoading)
              return const Center(child: CircularProgressIndicator());

            return Align(
              alignment: Alignment.topCenter,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 5.0,
                onInteractionEnd: (_) => _resetScaleAfterDelay(),
                child: SizedBox(
                  width: svgWidth * totalScale,
                  height: svgHeight * totalScale,
                  child: Stack(
                    children: [
                      Positioned(
                          left: leftOffset,
                          top: topOffset,
                          child: SvgPicture.asset(svgAsset,
                              width: svgDisplayWidth,
                              height: svgDisplayHeight)),
                      ..._buttonData.map((buttonData) {
                        final roomId = buttonData['id'] as String;
                        final isSelected = roomId == selectedRoomId;
                        final color = isSelected
                            ? Colors.blue.withOpacity(0.7)
                            : Colors.blue.withOpacity(0.2);
                        if (buttonData.containsKey('path')) {
                          return Positioned(
                              left: leftOffset,
                              top: topOffset,
                              child: GestureDetector(
                                  onTap: () =>
                                      _showRoomInfoSheet(context, roomId),
                                  child: CustomPaint(
                                      size: Size(
                                          svgDisplayWidth, svgDisplayHeight),
                                      painter: RoomShapePainter(
                                          svgPathData: buttonData['path'],
                                          color: color,
                                          scale: totalScale * svgScale))));
                        } else {
                          return Positioned(
                              left: buttonData["x"] * totalScale * svgScale +
                                  leftOffset,
                              top: buttonData["y"] * totalScale * svgScale +
                                  topOffset,
                              width:
                                  buttonData["width"] * totalScale * svgScale,
                              height:
                                  buttonData["height"] * totalScale * svgScale,
                              child: InkWell(
                                  onTap: () => _showRoomInfoSheet(
                                      context, buttonData["id"]),
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      color: color)));
                        }
                      }).toList(),

                      // ★★★ 계산된 최단 경로를 그리는 부분 ★★★
                      if (_shortestPath.isNotEmpty)
                        Positioned(
                          left: leftOffset,
                          top: topOffset,
                          child: IgnorePointer(
                            child: CustomPaint(
                              size: Size(svgDisplayWidth, svgDisplayHeight),
                              painter: PathPainter(
                                pathNodeIds: _shortestPath, // 계산된 경로 노드 ID 리스트
                                allNodes: _navNodes, // 전체 노드 좌표 정보
                                scale: totalScale * svgScale,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Positioned(
            left: 20,
            bottom: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: Column(
                  children: floors.map((floor) {
                    final isSelected = floor == selectedFloor;
                    return GestureDetector(
                        onTap: () => _onFloorChanged(floor),
                        child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            color: isSelected
                                ? Colors.indigo[400]
                                : Colors.transparent,
                            child: Text('$floor',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.indigo))));
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
