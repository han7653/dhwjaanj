// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'room_info.dart';
// import 'svg_data_parser.dart'; // 층별로 svgRects_1f, svgRects_2f 등 분리
// import 'room_info_sheet.dart';

// // 층별 SVG 맵을 보여주는 위젯
// class FloorMapView extends StatefulWidget {
//   final int floor; // 몇 층을 보여줄지 결정하는 변수
//   const FloorMapView({super.key, required this.floor});

//   @override
//   State<FloorMapView> createState() => _FloorMapViewState();
// }

// class _FloorMapViewState extends State<FloorMapView> {
//   String? selectedRoomId; // 현재 선택된 방의 id

//   @override
//   Widget build(BuildContext context) {
//     // 층별로 사용할 SVG 파일과 방 위치 데이터 분기
//     String svgAsset;
//     List<Map<String, dynamic>> svgRects;
//     switch (widget.floor) {
//       case 3:
//         svgAsset = 'assets/w19_3.svg';
//         svgRects = svgRects_3f;
//         break;
//       case 2:
//         svgAsset = 'assets/w19_2.svg';
//         svgRects = svgRects_2f;
//         break;
//       case 1:
//       default:
//         svgAsset = 'assets/w19_1.svg';
//         svgRects = svgRects_1f;
//     }

//     // SVG 원본의 크기 (A4 세로 비율 등)
//     const double svgWidth = 210;
//     const double svgHeight = 297;

//     // 화면 크기에 맞게 SVG를 스케일링
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // 가로, 세로 비율에 맞는 스케일 계산
//         final double scaleX = constraints.maxWidth / svgWidth;
//         final double scaleY = constraints.maxHeight / svgHeight;
//         final double baseScale = scaleX < scaleY ? scaleX : scaleY;

//         return Center(
//           child: InteractiveViewer(
//             minScale: 0.5, // 최소 확대/축소 비율
//             maxScale: 5.0, // 최대 확대/축소 비율
//             child: SizedBox(
//               width: svgWidth * baseScale,
//               height: svgHeight * baseScale,
//               child: Stack(
//                 children: [
//                   // SVG 맵 표시
//                   SvgPicture.asset(
//                     svgAsset,
//                     width: svgWidth * baseScale,
//                     height: svgHeight * baseScale,
//                     fit: BoxFit.fill,
//                   ),
//                   // 각 방마다 터치 가능한 사각형 오버레이 생성
//                   ...svgRects.map((rect) {
//                     final isSelected = rect["id"] == selectedRoomId; // 선택 여부
//                     return Positioned(
//                       left: rect["x"] * baseScale,
//                       top: rect["y"] * baseScale,
//                       width: rect["width"] * baseScale,
//                       height: rect["height"] * baseScale,
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 220),
//                         curve: Curves.easeOutCubic,
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? Colors.red.withOpacity(0.16) // 선택 시 붉은색 반투명
//                               : Colors.transparent,
//                           borderRadius: BorderRadius.zero,
//                           boxShadow: isSelected
//                               ? [
//                                   BoxShadow(
//                                     color: Colors.red.withOpacity(0.13),
//                                     blurRadius: 14,
//                                     spreadRadius: 1,
//                                   ),
//                                 ]
//                               : [],
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.zero,
//                             onTap: () async {
//                               // 방 선택 시 하이라이트 및 상세 정보 시트 표시
//                               setState(() {
//                                 selectedRoomId = rect["id"];
//                               });
//                               await showModalBottomSheet(
//                                 context: context,
//                                 backgroundColor: Colors.transparent,
//                                 barrierColor: Colors.black.withOpacity(0.2),
//                                 isScrollControlled: true,
//                                 builder: (context) => RoomInfoSheet(
//                                   roomInfo: roomInfos[rect["id"]]!,
//                                   initialChildSize: 0.21,
//                                   minChildSize: 0.10,
//                                   maxChildSize: 0.22,
//                                   onDeparture: () {
//                                     Navigator.pop(context);
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text('${roomInfos[rect["id"]]!.name}를 출발지로 지정했습니다!')),
//                                     );
//                                   },
//                                   onArrival: () {
//                                     Navigator.pop(context);
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text('${roomInfos[rect["id"]]!.name}를 도착지로 지정했습니다!')),
//                                     );
//                                   },
//                                 ),
//                               );
//                               // 시트 닫으면 선택 해제
//                               setState(() {
//                                 selectedRoomId = null;
//                               });
//                             },
//                             splashColor: Colors.red.withOpacity(0.12), // 터치 효과
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
