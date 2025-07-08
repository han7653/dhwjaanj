// lib/main.dart (수정된 코드)

import 'package:flutter/material.dart';
import 'package:hatesvg/building_select_page.dart'; // 수정: 건물 선택 페이지 import

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
      // 수정: 앱의 첫 화면을 BuildingSelectPage로 변경
      home: const BuildingSelectPage(),
    );
  }
}
