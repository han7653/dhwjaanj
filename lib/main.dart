// lib/main.dart

import 'package:flutter/material.dart';         // Flutter 기본 위젯 패키지 import
import 'building_select_page.dart';            // 건물 선택 페이지 import

// 앱 진입점(main 함수). 앱을 실행할 때 가장 먼저 호출됨.
void main() {
  runApp(const MyApp());                       // MyApp 위젯을 최상위(root)로 실행
}

// 앱의 루트 위젯(StatelessWidget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건물 도면 안내',                   // 앱의 타이틀(앱 스위처 등에서 사용)
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,           // 전체 색상 테마(파란색 계열)
        useMaterial3: true,                     // 머티리얼3 디자인 사용
        brightness: Brightness.light,           // 밝은 테마
      ),
      // 앱이 시작할 때 보여줄 첫 화면을 지정
      home: const BuildingSelectPage(),         // ★ 건물 선택 페이지가 첫 화면!
    );
  }
}
