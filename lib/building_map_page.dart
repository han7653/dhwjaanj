import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'room_info_sheet.dart';       // 방 정보 바텀시트 위젯
import 'room_shape_painter.dart';    // path형 버튼 그리기용 CustomPainter
import 'path_painter.dart';          // 경로 표시용 CustomPainter
import 'building_map_config.dart';   // 건물별 데이터 모델

class BuildingMapPage extends StatefulWidget {
  final BuildingMapConfig config; // 건물별 데이터 주입
  const BuildingMapPage({super.key, required this.config});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  int selectedFloor = 1;        // 현재 선택된 층
  String? selectedRoomId;       // 선택된 방 ID
  String? startNodeId;          // 길찾기 출발 노드 ID
  String? endNodeId;            // 길찾기 도착 노드 ID

  List<Map<String, dynamic>> _buttonData = []; // SVG에서 파싱한 버튼 정보
  bool _isLoading = true;                      // 로딩 상태

  static const double svgScale = 0.7;          // SVG 크기 비율
  static const double svgWidth = 210;          // SVG 원본 너비
  static const double svgHeight = 297;         // SVG 원본 높이

  final TransformationController _transformationController = TransformationController(); // 확대/축소 컨트롤러
  Timer? _resetTimer; // 확대/축소 자동 복원 타이머

  @override
  void initState() {
    super.initState();
    _loadFloorData(selectedFloor); // 첫 진입 시 1층 데이터 로딩
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  // 층별 SVG 네트워크 다운로드 및 버튼 데이터 파싱
  Future<void> _loadFloorData(int floor) async {
    setState(() => _isLoading = true);
    try {
      final svgString = await fetchSvgString(widget.config.svgUrls[floor]!);
      final buttons = parseButtonDataFromString(svgString);
      if (mounted) {
        setState(() {
          _buttonData = buttons;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _buttonData = [];
        _isLoading = false;
      });
      print('SVG 다운로드 또는 파싱 오류: $e');
    }
  }

  // 네트워크에서 SVG 파일 다운로드
  Future<String> fetchSvgString(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('SVG 다운로드 실패');
    }
  }

  // SVG 문자열에서 rect/path 버튼 정보 파싱
  List<Map<String, dynamic>> parseButtonDataFromString(String svgString) {
    try {
      final document = XmlDocument.parse(svgString);
      final clickableGroups = document
          .findAllElements('g')
          .where((node) => node.getAttribute('id') == 'Clickable_Rooms');
      if (clickableGroups.isEmpty) return [];
      final clickableGroup = clickableGroups.first;
      final buttonList = <Map<String, dynamic>>[];

      // rect(사각형) 버튼 파싱
      clickableGroup.findElements('rect').forEach((rect) {
        buttonList.add({
          'id': rect.getAttribute('id') ?? '',
          'x': double.tryParse(rect.getAttribute('x') ?? '0.0') ?? 0.0,
          'y': double.tryParse(rect.getAttribute('y') ?? '0.0') ?? 0.0,
          'width': double.tryParse(rect.getAttribute('width') ?? '0.0') ?? 0.0,
          'height': double.tryParse(rect.getAttribute('height') ?? '0.0') ?? 0.0,
        });
      });

      // path(복잡한 도형) 버튼 파싱
      clickableGroup.findElements('path').forEach((path) {
        buttonList.add({
          'id': path.getAttribute('id') ?? '',
          'path': path.getAttribute('d') ?? '',
        });
      });

      return buttonList;
    } catch (e) {
      print('네트워크 SVG 버튼 데이터 파싱 오류: $e');
      return [];
    }
  }

  // 층 변경 시 호출
  void _onFloorChanged(int newFloor) {
    setState(() {
      selectedFloor = newFloor;
      selectedRoomId = null;
      startNodeId = null;
      endNodeId = null;
      _loadFloorData(newFloor);
    });
  }

  // 방 버튼 클릭 시 바텀시트로 방 정보 표시
  void _showRoomInfoSheet(BuildContext context, String id) async {
    final roomInfo = widget.config.roomInfos[id];
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
          });
          Navigator.pop(context);
        },
        onArrival: () {
          setState(() {
            endNodeId = id.startsWith('R') ? id.substring(1) : id;
          });
          Navigator.pop(context);
        },
      ),
    );
    if (mounted) setState(() => selectedRoomId = null);
  }

  // 확대/축소 후 5초 뒤 원상태로 복원
  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 층수 리스트를 오름차순 정렬 후 역순으로 만들어 아래에서 위로 1,2,3 순서로 쌓이게 함
    final floors = widget.config.svgUrls.keys.toList()..sort();
    final reversedFloors = floors.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.config.name} 안내도')),
      body: Stack(
        children: [
          // 도면 및 버튼/경로 표시
          LayoutBuilder(
            builder: (context, constraints) {
              // 화면에 맞는 스케일 계산
              final scaleX = constraints.maxWidth / svgWidth;
              final scaleY = constraints.maxHeight / svgHeight;
              final baseScale = scaleX < scaleY ? scaleX : scaleY;
              const viewScale = 1.0;
              final totalScale = baseScale * viewScale;

              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // SVG 및 버튼/경로의 실제 표시 크기 및 위치 보정
              final double svgDisplayWidth = svgWidth * totalScale * svgScale;
              final double svgDisplayHeight = svgHeight * totalScale * svgScale;
              final double leftOffset = (svgWidth * totalScale - svgDisplayWidth) / 2;
              final double topOffset = (svgHeight * totalScale - svgDisplayHeight) / 2;

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
                        // SVG 도면 이미지
                        Positioned(
                          left: leftOffset,
                          top: topOffset,
                          child: SvgPicture.network(
                            widget.config.svgUrls[selectedFloor]!,
                            width: svgDisplayWidth,
                            height: svgDisplayHeight,
                            placeholderBuilder: (context) =>
                                const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        // 각 방 버튼/영역 그리기
                        ..._buttonData.map((buttonData) {
                          final String roomId = buttonData['id'];
                          final isSelected = roomId == selectedRoomId;
                          final color = isSelected
                              ? Colors.blue.withOpacity(0.7)
                              : Colors.blue.withOpacity(0.2);

                          // path(복잡한 도형) 버튼
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
                            // rect(사각형) 버튼
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
                        // 경로(길찾기) 표시
                        if (startNodeId != null && endNodeId != null)
                          Positioned(
                            left: leftOffset,
                            top: topOffset,
                            child: IgnorePointer(
                              child: CustomPaint(
                                size: Size(svgDisplayWidth, svgDisplayHeight),
                                painter: PathPainter(
                                  startPoint: widget.config.navNodes[startNodeId]!
                                      .position
                                      .scale(totalScale * svgScale, totalScale * svgScale),
                                  endPoint: widget.config.navNodes[endNodeId]!
                                      .position
                                      .scale(totalScale * svgScale, totalScale * svgScale),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // 층수 버튼(아래에서 위로 1,2,3 순서)
          Positioned(
            left: 20,
            bottom: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: Column(
                  children: reversedFloors.map((floor) {
                    final isSelected = floor == selectedFloor;
                    return GestureDetector(
                      onTap: () => _onFloorChanged(floor),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        color: isSelected ? Colors.indigo[400] : Colors.transparent,
                        child: Text(
                          '$floor',
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
}
