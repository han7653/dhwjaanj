// lib/building_map_page.dart (서버 구조에 맞춘 최종 수정본)

// 필요한 모든 패키지들을 불러옵니다.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'api_service.dart'; // 서버와 통신하는 서비스
import 'svg_data_parser.dart'; // SVG 내용을 직접 파싱하는 클래스 (필수)
import 'room_info.dart'; // 강의실 정보 데이터 모델
import 'room_info_sheet.dart'; // 하단 정보 시트 UI
import 'room_shape_painter.dart'; // 비정형 강의실 모양을 그리는 클래스
import 'navigation_data.dart'; // NavNode 클래스 및 길찾기 '연결' 정보
import 'path_painter.dart'; // 계산된 경로를 지도에 그리는 클래스
import 'pathfinding_service.dart'; // 최단 경로 계산 서비스

class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage({super.key});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --------------------------------------------------
  // 1. 상태 변수 (State Variables)
  // - 이 위젯의 모든 상태를 관리하는 변수들입니다.
  // --------------------------------------------------

  // --- 서버 데이터 관련 ---
  final String _buildingName = 'W19'; // 건물 이름은 'W19'로 고정하여 사용
  List<dynamic> _floorList =
      []; // 서버에서 받아온 W19 건물의 층 목록 (예: [{'Floor_Id': 3, 'Floor_Number': '1'}, ...])
  Map<String, dynamic>? _selectedFloor; // 사용자가 선택한 층의 전체 정보 (위 목록의 요소 하나)

  // --- 지도 데이터 관련 ---
  String? _svgContent; // 서버에서 다운로드한 SVG 파일의 전체 텍스트 내용
  List<Map<String, dynamic>> _buttonData = []; // SVG에서 파싱한 버튼(강의실)의 좌표 및 모양 정보
  Map<String, NavNode> _navNodes = {}; // SVG에서 파싱한 길찾기 노드의 ID와 좌표 정보

  // --- 길찾기 관련 ---
  List<String> _shortestPath = []; // 계산된 최단 경로 노드 ID 리스트
  String? selectedRoomId; // 현재 선택(탭)된 강의실의 ID
  String? startNodeId; // 길찾기 출발지 노드 ID
  String? endNodeId; // 길찾기 도착지 노드 ID

  // --- UI 상태 관련 ---
  bool _isFloorListLoading = true; // 앱 시작 시 층 목록을 로딩 중인지 여부
  bool _isMapLoading = false; // 특정 층의 지도를 로딩(다운로드 및 파싱) 중인지 여부

  // --- 서비스 및 컨트롤러 인스턴스 ---
  final ApiService _apiService = ApiService();
  final PathfindingService _pathfindingService = PathfindingService();
  final TransformationController _transformationController =
      TransformationController();
  Timer? _resetTimer; // 지도 자동 리셋을 위한 타이머
  static const double svgScale = 0.7; // 지도 기본 스케일

  // --------------------------------------------------
  // 2. 생명주기 및 데이터 로딩 (Lifecycle & Data Loading)
  // - 위젯이 생성/소멸되거나, 서버에서 데이터를 받아오는 로직
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadFloorList(); // 위젯이 처음 생성될 때, 층 목록을 불러오는 함수를 즉시 호출
  }

  @override
  void dispose() {
    _resetTimer?.cancel(); // 위젯이 사라질 때 타이머를 반드시 취소
    _transformationController.dispose(); // 컨트롤러 리소스 해제
    super.dispose();
  }

  /// 1단계: 서버에서 'W19' 건물의 층 목록을 가져옵니다.
  Future<void> _loadFloorList() async {
    setState(() => _isFloorListLoading = true); // 로딩 시작
    try {
      // ApiService를 통해 서버에 층 목록을 요청합니다.
      final floors = await _apiService.fetchFloorList(_buildingName);
      if (mounted) {
        // 위젯이 화면에 아직 존재하는 경우에만 상태 업데이트
        setState(() {
          _floorList = floors; // 받아온 층 목록으로 상태 업데이트
          _isFloorListLoading = false; // 로딩 완료
        });

        // 층 목록을 성공적으로 받아오면, 첫 번째 층을 자동으로 선택하고 지도를 불러옵니다.
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first);
        }
      }
    } catch (e) {
      print('층 목록 로딩 실패: $e');
      if (mounted) setState(() => _isFloorListLoading = false);
    }
  }

  /// 2단계: 특정 층의 상세 지도 데이터를 불러옵니다. (SVG 다운로드 및 파싱)
  /// 2단계: 특정 층의 상세 지도 데이터를 불러옵니다. (SVG 다운로드 및 파싱)
  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    setState(() {
      _isMapLoading = true; // 지도 로딩 시작
      _clearMapData();      // 새 지도를 불러오기 전, 이전 지도 관련 데이터를 모두 초기화
    });

    try {
      // =======================================================================
      // ★★★★★★★★★★★★★ 최종 수정된 부분 ★★★★★★★★★★★★★
      //
      // 더 이상 URL을 직접 만들지 않습니다.
      // 서버가 'rows' 배열 안의 'File' 필드에 담아준 실제 링크를 그대로 사용합니다.
      //
      final String? svgUrl = floorInfo['File'];
      // =======================================================================

      // 만약 서버에서 받은 URL이 null이거나 비어있으면, 함수를 중단합니다.
      if (svgUrl == null || svgUrl.isEmpty) {
        throw Exception('서버에서 받은 SVG URL이 유효하지 않습니다.');
      }

      // ApiService를 통해 해당 URL의 SVG 파일 내용을 통째로 다운로드합니다.
      final svgContent = await _apiService.fetchSvgContent(svgUrl);

      // 다운로드한 SVG 텍스트를 SvgDataParser에 넘겨 좌표 데이터를 추출(파싱)합니다.
      final buttons = SvgDataParser.parseButtonData(svgContent);
      final nodes = SvgDataParser.parseNavigationNodes(svgContent);

      if (mounted) {
        setState(() {
          _svgContent = svgContent; // 다운로드한 SVG 내용 저장
          _buttonData = buttons;    // 파싱한 버튼 정보 저장
          _navNodes = nodes;        // 파싱한 노드 정보 저장
          _isMapLoading = false;    // 지도 로딩 완료
        });
      }
    } catch (e) {
      print('[${floorInfo['Floor_Number']}층] 지도 데이터 로딩 실패: $e');
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // --------------------------------------------------
  // 3. 핵심 로직 및 보조 함수 (Core Logic & Helpers)
  // --------------------------------------------------

  /// 길찾기에 필요한 '노드 연결 정보(Adjacency List)'를 반환하는 getter.
  /// 이 정보는 서버에서 오지 않으므로, 앱 내부('navigation_data.dart')에 미리 정의해두고 사용합니다.
  Map<String, List<String>> get currentAdjacencyList {
    if (_selectedFloor == null) return {};

    // ★★★ [수정된 부분] ★★★
    // 서버에서 받은 'Floor_Id' (3 또는 5)에 따라
    // 'navigation_data.dart'에 정의된 정확한 변수를 반환합니다.
    switch (_selectedFloor!['Floor_Id']) {
      case 3:
        return floor3AdjacencyList; // 1층(Floor_Id: 3)을 위한 연결 정보
      case 5:
        return floor5AdjacencyList; // 2층(Floor_Id: 5)을 위한 연결 정보
      default:
        return {}; // 해당 층의 정보가 없으면 빈 맵 반환
    }
  }

  /// 최단 경로를 계산하고 화면을 다시 그리도록 요청하는 함수.
  void _findAndDrawPath() {
    if (startNodeId == null || endNodeId == null || _navNodes.isEmpty) return;

    // 1. 노드 좌표 정보와 연결 정보를 합쳐 '가중치 그래프'를 동적으로 생성
    final graph = _createWeightedGraph(_navNodes, currentAdjacencyList);

    // 2. 길찾기 서비스를 이용해 최단 경로(노드 ID 리스트)를 계산
    final path = _pathfindingService.findShortestPath(
      startId: startNodeId!,
      endId: endNodeId!,
      graph: graph,
    );

    // 3. 계산된 경로를 상태 변수에 저장하고, 화면을 다시 그리도록 요청(setState)
    setState(() => _shortestPath = path);
  }

  /// 가중치 그래프를 만드는 보조 함수 (수정 필요 없음)
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
        }
      }
    });
    return graph;
  }

  /// 층을 변경할 때, 이전 층의 지도 관련 데이터를 모두 지우는 함수.
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

  // --------------------------------------------------
  // 4. 이벤트 핸들러 (Event Handlers)
  // - 사용자의 입력(터치 등)에 반응하는 함수들
  // --------------------------------------------------

  /// 층 선택 버튼을 눌렀을 때 호출되는 함수.
  void _onFloorChanged(Map<String, dynamic> newFloor) {
    // 이미 선택된 층을 다시 누르면 아무것도 하지 않음
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id']) return;

    setState(() => _selectedFloor = newFloor); // 선택된 층 정보 업데이트
    _loadMapData(newFloor); // 해당 층의 상세 지도 데이터 불러오기 실행
  }

  /// 강의실을 탭했을 때 하단 정보 시트를 보여주는 함수.
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

  /// 지도 화면과 상호작용 후, 잠시 뒤에 원래 크기로 되돌리는 함수.
  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      _transformationController.value = Matrix4.identity();
    });
  }

  // --------------------------------------------------
  // 5. UI 빌드 (Build Method)
  // - 실제 화면을 구성하고 그리는 부분
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_buildingName 안내도')),
      body: Stack(
        children: [
          // 중앙 컨텐츠 영역 (지도 또는 안내 메시지)
          Center(child: _buildBodyContent()),

          // 좌측 하단 층 선택 버튼 UI
          if (!_isFloorListLoading) // 층 목록 로딩이 끝났을 때만 버튼을 보여줌
            Positioned(
              left: 20,
              bottom: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Column(
                    // 서버에서 받아온 _floorList로 동적으로 층 버튼들을 생성
                    children: _floorList.map((floor) {
                      final isSelected =
                          floor['Floor_Id'] == _selectedFloor?['Floor_Id'];
                      return GestureDetector(
                        onTap: () => _onFloorChanged(floor),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          color: isSelected
                              ? Colors.indigo[400]
                              : Colors.transparent,
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

  /// 현재 상태에 따라 중앙에 표시될 위젯을 결정하는 함수.
  Widget _buildBodyContent() {
    // 층 목록을 로딩 중이거나, 지도를 로딩 중일 때는 로딩 아이콘 표시
    if (_isFloorListLoading || _isMapLoading) {
      return const CircularProgressIndicator();
    }
    // 로딩이 끝났지만, SVG 내용이 없다면 (데이터 로딩 실패 등) 안내 메시지 표시
    if (_svgContent == null) {
      return const Text('지도를 불러올 수 없습니다.\n층을 선택해주세요.');
    }
    // 모든 데이터가 준비되면 지도 뷰를 생성하여 반환
    return _buildMapView();
  }

  /// 실제 지도를 그리는 위젯을 생성하는 함수.
  Widget _buildMapView() {
    const double svgWidth = 210, svgHeight = 297; // SVG 원본 크기
    return LayoutBuilder(builder: (context, constraints) {
      // 화면 크기에 맞춰 지도 크기를 동적으로 계산
      final scaleX = constraints.maxWidth / svgWidth;
      final scaleY = constraints.maxHeight / svgHeight;
      final baseScale = min(scaleX, scaleY);
      final totalScale = baseScale * 1.0;
      final double svgDisplayWidth = svgWidth * totalScale * svgScale;
      final double svgDisplayHeight = svgHeight * totalScale * svgScale;
      final double leftOffset = (svgWidth * totalScale - svgDisplayWidth) / 2;
      final double topOffset = (svgHeight * totalScale - svgDisplayHeight) / 2;

      return InteractiveViewer(
        // 확대/축소/이동이 가능한 뷰어
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 5.0,
        onInteractionEnd: (_) => _resetScaleAfterDelay(),
        child: SizedBox(
          width: svgWidth * totalScale,
          height: svgHeight * totalScale,
          child: Stack(
            // 여러 위젯을 겹쳐서 표현
            children: [
              // 1. 배경 지도 그리기
              Positioned(
                left: leftOffset,
                top: topOffset,
                child: SvgPicture.string(
                  _svgContent!,
                  width: svgDisplayWidth,
                  height: svgDisplayHeight,
                ),
              ),

              // 2. 상호작용 가능한 버튼(강의실)들 그리기 (★★★★★ 오류 수정된 부분 ★★★★★)
              ..._buttonData.map((buttonData) {
                final roomId = buttonData['id'] as String;
                final isSelected = roomId == selectedRoomId;
                final color = isSelected
                    ? Colors.blue.withOpacity(0.7)
                    : Colors.blue.withOpacity(0.2);

                // 버튼 모양이 복잡한 'path' 데이터로 정의된 경우
                if (buttonData.containsKey('path')) {
                  return Positioned(
                    left: leftOffset,
                    top: topOffset,
                    // ★ 오류 수정: Positioned 위젯에 child 속성을 추가했습니다.
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
                }
                // 버튼 모양이 단순한 '사각형'으로 정의된 경우
                else {
                  return Positioned(
                    left: buttonData["x"] * totalScale * svgScale + leftOffset,
                    top: buttonData["y"] * totalScale * svgScale + topOffset,
                    width: buttonData["width"] * totalScale * svgScale,
                    height: buttonData["height"] * totalScale * svgScale,
                    // ★ 오류 수정: Positioned 위젯에 child 속성을 추가했습니다.
                    child: InkWell(
                      onTap: () =>
                          _showRoomInfoSheet(context, buttonData["id"]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: color,
                      ),
                    ),
                  );
                }
              }).toList(),

              // 3. 계산된 최단 경로 그리기
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
