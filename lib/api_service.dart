// lib/api_service.dart (수정된 코드)

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "http://13.55.76.216:3000";

  /// W19 건물의 층 목록을 가져오는 함수
  Future<List<dynamic>> fetchFloorList(String buildingName) async {
    final response = await http.get(Uri.parse('$_baseUrl/floor/$buildingName'));
    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      return responseData['rows'] ?? []; // 'rows' 배열을 반환
    } else {
      throw Exception('Failed to load floor list for $buildingName');
    }
  }

  /// SVG 파일의 내용을 문자열로 다운로드하는 함수
  Future<String> fetchSvgContent(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('Failed to download SVG content from $url');
    }
  }
}
