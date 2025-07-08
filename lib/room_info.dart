// lib/room_info.dart

// 방 정보를 담는 데이터 클래스
class RoomInfo {
  final String id; // 방의 고유 ID (예: "R101")
  final String name; // 방 이름 (예: "101호")
  final String desc; // 방 설명 (예: "컴퓨터공학과 강의실")

  // 생성자: 모든 필드는 필수(required)
  RoomInfo({required this.id, required this.name, required this.desc});
}

// 각 방의 ID를 키로, RoomInfo 객체를 값으로 갖는 맵(Map)
// 층별로 방 정보를 담고 있음
final Map<String, RoomInfo> roomInfos = {
  // 1층 강의실 및 실험실 정보
  "R101": RoomInfo(id: "R101", name: "101호", desc: "컴퓨터공학과 강의실"),
  "R102": RoomInfo(id: "R102", name: "102호", desc: "전자공학과 강의실"),
  "R103": RoomInfo(id: "R103", name: "103호", desc: "기계공학과 강의실"),
  "R104": RoomInfo(id: "R104", name: "104호", desc: "화학공학과 실험실"),
  "R105": RoomInfo(id: "R105", name: "105호", desc: "물리학과 강의실"),
  "R106": RoomInfo(id: "R106", name: "106호", desc: "생명과학과 실험실"),
  "R107": RoomInfo(id: "R107", name: "107호", desc: "수학과 강의실"),
  "R108": RoomInfo(id: "R108", name: "108호", desc: "영어영문학과 강의실"),
  "R109": RoomInfo(id: "R109", name: "109호", desc: "역사학과 강의실"),
  "R110": RoomInfo(id: "R110", name: "110호", desc: "철학과 강의실"),
  "R111": RoomInfo(id: "R111", name: "111호", desc: "심리학과 강의실"),

  // 2층 강의실 및 연구실 정보
  "R112": RoomInfo(id: "R112", name: "112호", desc: "사회학과 강의실"),
  "R201": RoomInfo(id: "R201", name: "201호", desc: "공용 강의실 또는 연구실"),
  "R202": RoomInfo(id: "R202", name: "202호", desc: "공용 강의실 또는 연구실"),
  "R203": RoomInfo(id: "R203", name: "203호", desc: "공용 강의실 또는 연구실"),
  "R204": RoomInfo(id: "R204", name: "204호", desc: "공용 강의실 또는 연구실"),
  "R205": RoomInfo(id: "R205", name: "205호", desc: "공용 강의실 또는 연구실"),
  "R206": RoomInfo(id: "R206", name: "206호", desc: "공용 강의실 또는 연구실"),
  "R207": RoomInfo(id: "R207", name: "207호", desc: "공용 강의실 또는 연구실"),
  "R208": RoomInfo(id: "R208", name: "208호", desc: "공용 강의실 또는 연구실"),
  "R209": RoomInfo(id: "R209", name: "209호", desc: "공용 강의실 또는 연구실"),
  "R210": RoomInfo(id: "R210", name: "210호", desc: "공용 강의실 또는 연구실"),
  "R211": RoomInfo(id: "R211", name: "211호", desc: "공용 강의실 또는 연구실"),
  "R212": RoomInfo(id: "R212", name: "212호", desc: "공용 강의실 또는 연구실"),
  "R213": RoomInfo(id: "R213", name: "213호", desc: "공용 강의실 또는 연구실"),
  "R214": RoomInfo(id: "R214", name: "214호", desc: "공용 강의실 또는 연구실"),
  "R215": RoomInfo(id: "R215", name: "215호", desc: "공용 강의실 또는 연구실"),
  "R216": RoomInfo(id: "R216", name: "216호", desc: "공용 강의실 또는 연구실"),
  "R217": RoomInfo(id: "R217", name: "217호", desc: "공용 강의실 또는 연구실"),
  "R218": RoomInfo(id: "R218", name: "218호", desc: "공용 강의실 또는 연구실"),
  "R219": RoomInfo(id: "R219", name: "219호", desc: "공용 강의실 또는 연구실"),
  "R220": RoomInfo(id: "R220", name: "220호", desc: "공용 강의실 또는 연구실"),
  "R221": RoomInfo(id: "R221", name: "221호", desc: "공용 강의실 또는 연구실"),
  "R222": RoomInfo(id: "R222", name: "222호", desc: "공용 강의실 또는 연구실"),
  "R223": RoomInfo(id: "R223", name: "223호", desc: "공용 강의실 또는 연구실"),
  "R224": RoomInfo(id: "R224", name: "224호", desc: "공용 강의실 또는 연구실"),
  "R225": RoomInfo(id: "R225", name: "225호", desc: "공용 강의실 또는 연구실"),
  "R226": RoomInfo(id: "R226", name: "226호", desc: "공용 강의실 또는 연구실"),
  "R227": RoomInfo(id: "R227", name: "227호", desc: "공용 강의실 또는 연구실"),
  "R228": RoomInfo(id: "R228", name: "228호", desc: "공용 강의실 또는 연구실"),
  "R229": RoomInfo(id: "R229", name: "229호", desc: "공용 강의실 또는 연구실"),
  "R230": RoomInfo(id: "R230", name: "230호", desc: "공용 강의실 또는 연구실"),
  "R231": RoomInfo(id: "R231", name: "231호", desc: "공용 강의실 또는 연구실"),
  "R232": RoomInfo(id: "R232", name: "232호", desc: "공용 강의실 또는 연구실"),
  "R233": RoomInfo(id: "R233", name: "233호", desc: "공용 강의실 또는 연구실"),

  // 3층 테라스 정보
  "Terrace": RoomInfo(id: "Terrace", name: "테라스", desc: "야외 테라스 공간"),
};