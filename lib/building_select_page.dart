// lib/building_select_page.dart (임시 수정 코드)

import 'package:flutter/material.dart';
import 'package:hatesvg/building_map_page.dart';

class BuildingSelectPage extends StatelessWidget {
  const BuildingSelectPage({super.key});

  // [수정] 서버 API 호출이 실패하므로, 테스트를 위해 다시 하드코딩된 리스트를 사용합니다.
  // 현재 SVG 데이터가 있는 W19 건물만 리스트에 추가합니다.
  final List<String> buildingList = const ['W19'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건물 선택'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: buildingList.length,
        itemBuilder: (context, index) {
          final buildingName = buildingList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo[100],
                child: const Icon(Icons.business, color: Colors.indigo),
              ),
              title: Text(
                buildingName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$buildingName 실내 지도 보기'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BuildingMapPage(buildingName: buildingName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
