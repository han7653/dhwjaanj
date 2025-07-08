// lib/building_map_page.dart (수정된 최종 코드)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'svg_data_parser.dart';
import 'room_info.dart';
import 'room_info_sheet.dart';
import 'room_shape_painter.dart';
import 'path_painter.dart';

class BuildingMapPage extends StatefulWidget {
  final String buildingName;
  const BuildingMapPage({super.key, required this.buildingName});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --- 상태 변수 ---
  List<dynamic> _floorList = [];
  Map<String, dynamic>? _selectedFloor;
  String? _svgUrl;
  List<Map<String, dynamic>> _buttonData = [];
  Map<String, Offset> _navNodes = {};

  // 길찾기 관련 상태
  Map<String, dynamic>? _startPoint;
  Map<String, dynamic>? _endPoint;
  List<Offset> _shortestPath = [];

  // 로딩 및 에러 상태 관리
  bool _isFloorListLoading = true;
  bool _isMapLoading = false;
  String? _error;

  String? _selectedRoomId;
  final ApiService _apiService = ApiService();
  final TransformationController _transformationController = TransformationController();
  Timer? _resetTimer;
  static const double svgScale = 0.7;

  @override
  void initState() {
    super.initState();
    _loadFloorList(widget.buildingName);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFloorList(String buildingName) async {
    setState(() {
      _isFloorListLoading = true;
      _error = null;
    });
    try {
      final floors = await _apiService.fetchFloorList(buildingName);
      if (mounted) {
        setState(() {
          _floorList = floors;
          _isFloorListLoading = false;
        });
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first);
        } else {
          setState(() => _error = "이 건물의 층 정보를 찾을 수 없습니다.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFloorListLoading = false;
          _error = '층 목록을 불러오는 데 실패했습니다: $e';
        });
      }
    }
  }

  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    try {
      final String? svgUrl = floorInfo['File'];
      if (svgUrl == null || svgUrl.isEmpty) throw Exception('SVG URL이 유효하지 않습니다.');

      final svgResponse = await http.get(Uri.parse(svgUrl));
      if (svgResponse.statusCode != 200) throw Exception('SVG 파일을 다운로드할 수 없습니다 (Status: ${svgResponse.statusCode})');
      final svgContent = svgResponse.body;
      
      final buttons = SvgDataParser.parseButtonData(svgContent);
      final nodes = SvgDataParser.parseNavigationNodes(svgContent);

      if (mounted) {
        setState(() {
          _svgUrl = svgUrl;
          _buttonData = buttons;
          _navNodes = nodes;
          _isMapLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _error = '지도 데이터를 불러오는 데 실패했습니다: $e';
        });
      }
    }
  }
  
  void _onFloorChanged(Map<String, dynamic> newFloor) {
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null) return;
    
    setState(() {
      _selectedFloor = newFloor;
      _shortestPath = [];
      _startPoint = null;
      _endPoint = null;
      _error = null;
      _svgUrl = null;
      _isMapLoading = true;
    });
    
    _loadMapData(newFloor); 
  }

  // [핵심 수정] 길찾기 API 호출 시 서버 요구사항에 맞춰 Room ID의 'R' 접두사 제거
  Future<void> _findAndDrawPath() async {
    if (_startPoint == null || _endPoint == null) return;
    
    if (_startPoint!['floorId'] != _endPoint!['floorId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 다른 층 간 길찾기는 지원되지 않습니다.')),
      );
      return;
    }

    setState(() => _isMapLoading = true);

    try {
      // 서버 API로 보낼 ID 가공: 'R' 접두사 제거
      String fromRoomId = _startPoint!['roomId'];
      if (fromRoomId.startsWith('R')) {
        fromRoomId = fromRoomId.substring(1);
      }

      String toRoomId = _endPoint!['roomId'];
      if (toRoomId.startsWith('R')) {
        toRoomId = toRoomId.substring(1);
      }

      final response = await _apiService.findPath(
        fromBuilding: widget.buildingName,
        fromFloor: _startPoint!['floorId'],
        fromRoom: fromRoomId, // 'R'이 제거된 ID 사용
        toBuilding: widget.buildingName,
        toFloor: _endPoint!['floorId'],
        toRoom: toRoomId, // 'R'이 제거된 ID 사용
      );
      
      if (response['type'] == 'room-room' && response['result']?['arrival_indoor']?['path']?['path'] != null) {
        final pathData = response['result']['arrival_indoor']['path']['path'] as List;
        final newPath = pathData.map((p) => Offset(p['x'].toDouble(), p['y'].toDouble())).toList();
        setState(() => _shortestPath = newPath);
      } else {
        setState(() => _shortestPath = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경로를 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      setState(() => _shortestPath = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('길찾기 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if(mounted) setState(() => _isMapLoading = false);
    }
  }

  void _showRoomInfoSheet(BuildContext context, String roomId) async {
    final roomInfo = roomInfos[roomId];
    if (roomInfo == null) return;

    setState(() => _selectedRoomId = roomId);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomInfoSheet(
        roomInfo: roomInfo,
        onDeparture: () {
          setState(() => _startPoint = {"floorId": _selectedFloor?['Floor_Id'], "roomId": roomId});
          if (_endPoint != null) _findAndDrawPath();
          Navigator.pop(context);
        },
        onArrival: () {
          setState(() => _endPoint = {"floorId": _selectedFloor?['Floor_Id'], "roomId": roomId});
          if (_startPoint != null) _findAndDrawPath();
          Navigator.pop(context);
        },
      ),
    );
    if (mounted) setState(() => _selectedRoomId = null);
  }

  // --- UI 빌드 메서드 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.buildingName} 실내 안내도'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _startPoint = null;
                _endPoint = null;
                _shortestPath = [];
                _transformationController.value = Matrix4.identity();
              });
            },
            tooltip: '초기화',
          )
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildBodyContent()),
          if (!_isFloorListLoading && _error == null)
            Positioned(left: 16, bottom: 120, child: _buildFloorSelector()),
          _buildPathInfo(),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFloorListLoading) {
      return const Text('층 목록을 불러오는 중...');
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (_isMapLoading) {
      return const CircularProgressIndicator();
    }
    if (_svgUrl == null) {
      return const Text('층을 선택해주세요.');
    }
    return _buildMapView();
  }

  Widget _buildMapView() {
    const double svgWidth = 210, svgHeight = 297;
    return LayoutBuilder(builder: (context, constraints) {
      final baseScale = min(constraints.maxWidth / svgWidth, constraints.maxHeight / svgHeight);
      final totalScale = baseScale * 1.0;
      final svgDisplayWidth = svgWidth * totalScale * svgScale;
      final svgDisplayHeight = svgHeight * totalScale * svgScale;
      final leftOffset = (constraints.maxWidth - svgDisplayWidth) / 2;
      final topOffset = (constraints.maxHeight - svgDisplayHeight) / 2;

      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        onInteractionEnd: (details) => _resetScaleAfterDelay(),
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: leftOffset,
                top: topOffset,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  child: SvgPicture.network(
                    _svgUrl!,
                    width: svgDisplayWidth,
                    height: svgDisplayHeight,
                    placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              ..._buttonData.map((button) {
                final Rect rect = button['rect'];
                final String id = button['id'];
                final scaledRect = Rect.fromLTWH(
                  leftOffset + rect.left * totalScale * svgScale,
                  topOffset + rect.top * totalScale * svgScale,
                  rect.width * totalScale * svgScale,
                  rect.height * totalScale * svgScale,
                );
                return Positioned.fromRect(
                  rect: scaledRect,
                  child: GestureDetector(
                    onTap: () => _showRoomInfoSheet(context, id),
                    child: CustomPaint(
                      painter: RoomShapePainter(isSelected: _selectedRoomId == id),
                    ),
                  ),
                );
              }).toList(),
              if (_shortestPath.isNotEmpty)
                Positioned(
                  left: leftOffset,
                  top: topOffset,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(svgDisplayWidth, svgDisplayHeight),
                      painter: PathPainter(pathPoints: _shortestPath, scale: totalScale * svgScale),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFloorSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          children: _floorList.map((floor) {
            final bool isSelected = _selectedFloor?['Floor_Id'] == floor['Floor_Id'];
            return GestureDetector(
              onTap: () => _onFloorChanged(floor),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo.withOpacity(0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${floor['Floor_Number']}F',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPathInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointInfo("출발", _startPoint?['roomId'] ?? '미지정', Colors.green),
              const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
              _buildPointInfo("도착", _endPoint?['roomId'] ?? '미지정', Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointInfo(String title, String? id, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          id ?? '미지정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }
}
