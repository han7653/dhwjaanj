// lib/api_service.dart (수정된 전체 코드)

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "http://13.55.76.216:3000";

  /// 서버에서 선택 가능한 모든 건물 목록을 가져오는 함수
  /// 참고: 현재는 서버에 /buildings 엔드포인트가 없어 임시로 비활성화 되어있습니다.
  /// 추후 서버에 기능이 추가되면 BuildingSelectPage에서 호출 로직을 활성화할 수 있습니다.
  Future<List<String>> fetchBuildingList() async {
    final response = await http.get(Uri.parse('$_baseUrl/buildings'));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> buildingList = data['buildings'];
      return buildingList.cast<String>();
    } else {
      throw Exception('Failed to load building list from server');
    }
  }

  /// 특정 건물의 층 목록을 가져오는 함수
  Future<List<dynamic>> fetchFloorList(String buildingName) async {
    final response = await http.get(Uri.parse('$_baseUrl/floor/$buildingName'));
    if (response.statusCode == 200) {
      // [핵심 수정] 서버가 JSON 배열을 직접 반환하므로, 'rows' 키 없이 바로 디코딩합니다.
      final List<dynamic> floorList = json.decode(utf8.decode(response.bodyBytes));
      return floorList;
    } else {
      throw Exception('Failed to load floor list for $buildingName');
    }
  }

  /// 서버에 길찾기를 요청하는 함수
  Future<Map<String, dynamic>> findPath({
    required String fromBuilding,
    int? fromFloor,
    String? fromRoom,
    required String toBuilding,
    int? toFloor,
    String? toRoom,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'from_building': fromBuilding,
        'from_floor': fromFloor,
        'from_room': fromRoom,
        'to_building': toBuilding,
        'to_floor': toFloor,
        'to_room': toRoom,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to find path');
    }
  }
}
