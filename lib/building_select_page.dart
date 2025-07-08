import 'package:flutter/material.dart';
import 'building_map_config.dart';   // 건물별 데이터 모델 (BuildingMapConfig) import
import 'building_map_page.dart';    // 건물 도면 페이지 import
import 'room_info.dart';            // 방 정보 import (각 건물별로 따로 관리 가능)
import 'navigation_data.dart';      // 길찾기 노드 정보 import (각 건물별로 따로 관리 가능)

// 여러 건물의 도면/정보를 담는 리스트
final List<BuildingMapConfig> buildingConfigs = [
  BuildingMapConfig(
    name: '동관', // 건물 이름
    svgUrls: {   // 층별 SVG 도면 URL
      1: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W17-%EB%8F%99%EA%B4%80_1.svg',
      2: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W17-%EB%8F%99%EA%B4%80_2.svg',
      3: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W17-%EB%8F%99%EA%B4%80_3.svg',
    },
    roomInfos: roomInfos,     // 동관의 방 정보 (Map<String, RoomInfo>)
    navNodes: allNavNodes,    // 동관의 네비게이션 노드 정보 (Map<String, NavNode>)
  ),
  BuildingMapConfig(
    name: '서관',
    svgUrls: {
      1: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W18-%EC%84%9C%EA%B4%80_1.svg',
      2: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W18-%EC%84%9C%EA%B4%80_2.svg',
      3: 'https://wsu-map-svg.s3.ap-northeast-2.amazonaws.com/W18-%EC%84%9C%EA%B4%80_3.svg',
    },
    roomInfos: roomInfos,     // 서관의 방 정보 (실제로는 각 건물별로 따로 관리 권장)
    navNodes: allNavNodes,    // 서관의 네비게이션 노드 정보
  ),
  // ... 추가 건물은 같은 방식으로 계속 추가
];

/// 건물 선택 화면
class BuildingSelectPage extends StatelessWidget {
  const BuildingSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건물 선택'), // 상단 앱바 제목
      ),
      body: ListView(
        padding: const EdgeInsets.all(24), // 전체 여백
        children: buildingConfigs.map((config) {
          // buildingConfigs의 각 건물에 대해 버튼 생성
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12), // 버튼 간 세로 간격
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60), // 버튼 높이
                textStyle: const TextStyle(fontSize: 20), // 버튼 텍스트 크기
              ),
              onPressed: () {
                // 버튼 클릭 시 해당 건물의 도면 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuildingMapPage(config: config), // config 전달
                  ),
                );
              },
              child: Text(config.name), // 버튼 라벨: 건물 이름
            ),
          );
        }).toList(),
      ),
    );
  }
}
