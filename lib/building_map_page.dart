import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'svg_data_parser.dart'; // 경로 확인 필요
import 'room_info.dart';           // 경로 확인 필요
import 'room_info_sheet.dart';  // 경로 확인 필요
import 'room_shape_painter.dart'; // 경로 확인 필요
import 'navigation_data.dart';      // 경로 확인 필요
import 'path_painter.dart';      // 경로 확인 필요

class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage({super.key});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --------------------------------------------------
  // 1. 상태 변수 (State Variables)
  // --------------------------------------------------
  int selectedFloor = 1;
  String? selectedRoomId;
  String? startNodeId;
  String? endNodeId;

  List<Map<String, dynamic>> _buttonData = [];
  bool _isLoading = true;

  final List<int> floors = [3, 2, 1];

  String get svgAsset => 'assets/w19_$selectedFloor.svg';

  // --------------------------------------------------
  // 2. 생명주기 및 데이터 로딩 함수 (Lifecycle & Data Loading)
  // --------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadFloorData(selectedFloor);
  }

  Future<void> _loadFloorData(int floor) async {
    setState(() => _isLoading = true);
    final buttons = await SvgDataParser.parseButtonData('assets/w19_$floor.svg');
    if (mounted) {
      setState(() {
        _buttonData = buttons;
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------
  // 3. 이벤트 핸들러 (Event Handlers)
  // --------------------------------------------------
  void _onFloorChanged(int newFloor) {
    setState(() {
      selectedFloor = newFloor;
      selectedRoomId = null;
      startNodeId = null;
      endNodeId = null;
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

  // --------------------------------------------------
  // 4. UI 빌드 (Build Method)
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const double svgWidth = 210;
    const double svgHeight = 297;

    return Scaffold(
      appBar: AppBar(title: const Text('강의실 안내도')),
      body: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaleX = constraints.maxWidth / svgWidth;
                final scaleY = constraints.maxHeight / svgHeight;
                final baseScale = scaleX < scaleY ? scaleX : scaleY;
                const viewScale = 0.7;
                final totalScale = baseScale * viewScale;

                if (_isLoading) {
                  return const CircularProgressIndicator();
                }

                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: SizedBox(
                    width: svgWidth * totalScale,
                    height: svgHeight * totalScale,
                    child: Stack(
                      children: [
                        SvgPicture.asset(svgAsset, width: svgWidth * totalScale, height: svgHeight * totalScale),
                        ..._buttonData.map((buttonData) {
                          final String roomId = buttonData['id'];
                          final isSelected = roomId == selectedRoomId;
                          final color = isSelected ? Colors.blue.withOpacity(0.7) : Colors.blue.withOpacity(0.2);

                          if (buttonData.containsKey('path')) {
                            return GestureDetector(
                              onTap: () => _showRoomInfoSheet(context, roomId),
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: RoomShapePainter(
                                  svgPathData: buttonData['path'],
                                  color: color,
                                  scale: totalScale,
                                ),
                              ),
                            );
                          } else {
                            return Positioned(
                              left: buttonData["x"] * totalScale,
                              top: buttonData["y"] * totalScale,
                              width: buttonData["width"] * totalScale,
                              height: buttonData["height"] * totalScale,
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
                        if (startNodeId != null && endNodeId != null)
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: PathPainter(
                                startPoint: allNavNodes[startNodeId]!.position.scale(totalScale, totalScale),
                                endPoint: allNavNodes[endNodeId]!.position.scale(totalScale, totalScale),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                        color: isSelected ? Colors.indigo[400] : Colors.transparent,
                        child: Text(
                          '$floor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.indigo
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
