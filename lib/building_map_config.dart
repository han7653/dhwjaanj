import 'room_info.dart';
import 'navigation_data.dart';


class BuildingMapConfig {
  final String name;
  final Map<int, String> svgUrls; // 층별 SVG URL
  final Map<String, RoomInfo> roomInfos;
  final Map<String, NavNode> navNodes;

  BuildingMapConfig({
    required this.name,
    required this.svgUrls,
    required this.roomInfos,
    required this.navNodes,
  });
}
