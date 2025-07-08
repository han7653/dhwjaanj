// lib/main.dart (수정된 최종 코드)

import 'package:flutter/material.dart';
import 'package:hatesvg/building_map_page.dart'; // 지도 페이지를 import 합니다.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '실내 지도 앱',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // ★★★ 수정된 부분 ★★★
      // 더 이상 필요 없는 BuildingSelectPage 대신,
      // BuildingMapPage를 앱의 첫 화면으로 지정합니다.
      home: const BuildingMapPage(),
    );
  }
}
