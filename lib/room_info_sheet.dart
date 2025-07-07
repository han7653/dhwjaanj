// lib/room_info_sheet.dart

import 'package:flutter/material.dart';
import 'room_info.dart';

// 방 정보와 출발/도착 콜백을 받아 바텀시트로 보여주는 위젯
class RoomInfoSheet extends StatelessWidget {
  final RoomInfo roomInfo; // 방 정보 객체
  final VoidCallback onDeparture; // 출발 버튼 클릭 시 실행할 콜백
  final VoidCallback onArrival; // 도착 버튼 클릭 시 실행할 콜백
  final double initialChildSize; // 시트의 초기 크기 비율
  final double minChildSize; // 시트의 최소 크기 비율
  final double maxChildSize; // 시트의 최대 크기 비율

  const RoomInfoSheet({
    super.key,
    required this.roomInfo,
    required this.onDeparture,
    required this.onArrival,
    this.initialChildSize = 0.32,
    this.minChildSize = 0.32,
    this.maxChildSize = 0.37,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize, // 초기 시트 크기
      minChildSize: minChildSize, // 최소 시트 크기
      maxChildSize: maxChildSize, // 최대 시트 크기
      expand: false, // 전체 화면 확장 비활성화
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white, // 시트 배경색
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ), // 상단만 둥글게
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController, // 시트 내부 스크롤 컨트롤러
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20), // 내부 여백
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 시트 상단에 드래그 핸들(회색 바)
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 방 아이콘, 이름, 설명 표시
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.purple[50],
                        child: Icon(
                          Icons.meeting_room_outlined,
                          size: 22,
                          color: Colors.purple[400],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roomInfo.name, // 방 이름
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              roomInfo.desc, // 방 설명
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 출발/도착 버튼 영역
                  Row(
                    children: [
                      // 출발 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: onDeparture, // 출발 콜백 실행
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6DD5FA),
                                  Color(0xFF2980B9),
                                ], // 파란색 그라데이션
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.09),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.flag_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '출발',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 도착 버튼
                      Expanded(
                        child: GestureDetector(
                          onTap: onArrival, // 도착 콜백 실행
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF7971E),
                                  Color(0xFFFF5858),
                                ], // 주황-빨강 그라데이션
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.09),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '도착',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
