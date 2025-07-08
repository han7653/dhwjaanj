// lib/building_map_page.dart (전체 수정된 코드)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'api_service.dart';
import 'svg_data_parser.dart';
import 'room_info.dart';
import 'room_info_sheet.dart';
import 'room_shape_painter.dart';
import 'navigation_data.dart';
import 'path_painter.dart';
import 'pathfinding_service.dart';

class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage({super.key});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --- 1. 상태 변수 ---
  final String _buildingName = 'W19';
  List<dynamic> _floorList = [];
  Map<String, dynamic>? _selectedFloor;

  String? _svgContent;
  List<Map<String, dynamic>> _buttonData = [];
  Map<String, NavNode> _navNodes = {};

  List<String> _shortestPath = [];
  String? selectedRoomId, startNodeId, endNodeId;

  bool _isFloorListLoading = true;
  bool _isMapLoading = false;

  final ApiService _apiService = ApiService();
  final PathfindingService _pathfindingService = PathfindingService();
  final TransformationController _transformationController = TransformationController();
  Timer? _resetTimer;
  static const double svgScale = 0.7;

  // --- 2. 생명주기 및 데이터 로딩 ---
  @override
  void initState() {
    super.initState();
    _loadFloorList();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadFloorList() async {
    setState(() => _isFloorListLoading = true);
    try {
      final floors = await _apiService.fetchFloorList(_buildingName);
      if (mounted) {
        setState(() {
          _floorList = floors;
          _isFloorListLoading = false;
        });
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first);
        }
      }
    } catch (e) {
      print('층 목록 로딩 실패: $e');
      if (mounted) setState(() => _isFloorListLoading = false);
    }
  }

  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    setState(() {
      _isMapLoading = true;
      _clearMapData();
    });
    try {
      final String? svgUrl = floorInfo['File'];
      if (svgUrl == null || svgUrl.isEmpty) {
        throw Exception('서버에서 받은 SVG URL이 유효하지 않습니다.');
      }
      final svgContent = await _apiService.fetchSvgContent(svgUrl);
      final buttons = SvgDataParser.parseButtonData(svgContent);
      final nodes = SvgDataParser.parseNavigationNodes(svgContent);

      if (mounted) {
        setState(() {
          _svgContent = svgContent;
          _buttonData = buttons;
          _navNodes = nodes;
          _isMapLoading = false;
        });
      }
    } catch (e) {
      print('[${floorInfo['Floor_Number']}층] 지도 데이터 로딩 실패: $e');
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // --- 3. 핵심 로직 및 보조 함수 ---
  Map<String, List<String>> get currentAdjacencyList {
    if (_selectedFloor == null) return {};
    switch (_selectedFloor!['Floor_Id']) {
      case 3:
        return floor3AdjacencyList;
      case 5:
        return floor5AdjacencyList;
      default:
        return {};
    }
  }

  void _findAndDrawPath() {
    if (startNodeId == null || endNodeId == null || _navNodes.isEmpty) return;
    final graph = _createWeightedGraph(_navNodes, currentAdjacencyList);
    final path = _pathfindingService.findShortestPath(
      startId: startNodeId!,
      endId: endNodeId!,
      graph: graph,
    );
    setState(() => _shortestPath = path);
  }

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
          graph[nodeId]!.add(WeightedEdge(nodeId: neighborId, weight: distance));
        }
      }
    });
    return graph;
  }

  void _clearMapData() {
    setState(() {
      _svgContent = null;
      _buttonData = [];
      _navNodes = {};
      _shortestPath = [];
      selectedRoomId = null;
      startNodeId = null;
      endNodeId = null;
    });
  }

  // --- 4. 이벤트 핸들러 ---
  void _onFloorChanged(Map<String, dynamic> newFloor) {
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id']) return;
    setState(() => _selectedFloor = newFloor);
    _loadMapData(newFloor);
  }

  void _showRoomInfoSheet(BuildContext context, String id) async {
    final roomInfo = roomInfos[id];
    if (roomInfo == null) return;
    setState(() => selectedRoomId = id);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomInfoSheet(
        roomInfo: roomInfo,
        onDeparture: () {
          setState(() {
            startNodeId = id.startsWith('R') ? id.substring(1) : id;
            _findAndDrawPath();
          });
          Navigator.pop(context);
        },
        onArrival: () {
          setState(() {
            endNodeId = id.startsWith('R') ? id.substring(1) : id;
            _findAndDrawPath();
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

  // --- 5. UI 빌드 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_buildingName 안내도')),
      body: Stack(
        children: [
          Center(child: _buildBodyContent()),
          if (!_isFloorListLoading)
            Positioned(
              left: 20,
              bottom: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Column(
                    children: _floorList.map((floor) {
                      final isSelected = floor['Floor_Id'] == _selectedFloor?['Floor_Id'];
                      return GestureDetector(
                        onTap: () => _onFloorChanged(floor),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          color: isSelected ? Colors.indigo[400] : Colors.transparent,
                          child: Text(
                            '${floor['Floor_Number']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.indigo,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFloorListLoading || _isMapLoading) {
      return const CircularProgressIndicator();
    }
    if (_svgContent == null) {
      return const Text('지도를 불러올 수 없습니다.\n층을 선택해주세요.');
    }
    return _buildMapView();
  }

  Widget _buildMapView() {
    const double svgWidth = 210, svgHeight = 297;
    return LayoutBuilder(builder: (context, constraints) {
      final scaleX = constraints.maxWidth / svgWidth;
      final scaleY = constraints.maxHeight / svgHeight;
      final baseScale = min(scaleX, scaleY);
      final totalScale = baseScale * 1.0;
      final double svgDisplayWidth = svgWidth * totalScale * svgScale;
      final double svgDisplayHeight = svgHeight * totalScale * svgScale;
      final double leftOffset = (svgWidth * totalScale - svgDisplayWidth) / 2;
      final double topOffset = (svgHeight * totalScale - svgDisplayHeight) / 2;

      return InteractiveViewer(
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
                child: SvgPicture.string(
                  _svgContent!,
                  width: svgDisplayWidth,
                  height: svgDisplayHeight,
                ),
              ),
              ..._buttonData.map((buttonData) {
                final roomId = buttonData['id'] as String;
                final isSelected = roomId == selectedRoomId;
                final color = isSelected ? Colors.blue.withOpacity(0.7) : Colors.blue.withOpacity(0.2);
                if (buttonData.containsKey('path')) {
                  return Positioned(
                    left: leftOffset,
                    top: topOffset,
                    child: GestureDetector(
                      onTap: () => _showRoomInfoSheet(context, roomId),
                      child: CustomPaint(
                        size: Size(svgDisplayWidth, svgDisplayHeight),
                        painter: RoomShapePainter(
                          svgPathData: buttonData['path'],
                          color: color,
                          scale: totalScale * svgScale,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Positioned(
                    left: buttonData["x"] * totalScale * svgScale + leftOffset,
                    top: buttonData["y"] * totalScale * svgScale + topOffset,
                    width: buttonData["width"] * totalScale * svgScale,
                    height: buttonData["height"] * totalScale * svgScale,
                    child: InkWell(
                      onTap: () => _showRoomInfoSheet(context, buttonData["id"]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: color,
                      ),
                    ),
                  );
                }
              }).toList(),
              if (_shortestPath.isNotEmpty)
                Positioned(
                  left: leftOffset,
                  top: topOffset,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(svgDisplayWidth, svgDisplayHeight),
                      painter: PathPainter(
                        pathNodeIds: _shortestPath,
                        allNodes: _navNodes,
                        scale: totalScale * svgScale,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
