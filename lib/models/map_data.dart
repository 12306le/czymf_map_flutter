class MapData {
  final int code;
  final String msg;
  final GameData data;

  MapData({
    required this.code,
    required this.msg,
    required this.data,
  });

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      code: json['code'] ?? 0,
      msg: json['msg'] ?? '',
      data: GameData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'msg': msg,
        'data': data.toJson(),
      };
}

class GameData {
  final List<String> itemType;
  final List<ItemInfo> itemList;
  final List<MapPoint> xys;

  GameData({
    required this.itemType,
    required this.itemList,
    required this.xys,
  });

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      itemType: (json['item_type'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      itemList: (json['item_list'] as List?)
              ?.map((e) => ItemInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      xys: (json['xys'] as List?)
              ?.map((e) => MapPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'item_type': itemType,
        'item_list': itemList.map((e) => e.toJson()).toList(),
        'xys': xys.map((e) => e.toJson()).toList(),
      };
}

class ItemInfo {
  final int catId;
  final String name;
  final String type;

  ItemInfo({
    required this.catId,
    required this.name,
    required this.type,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      catId: (json['cat_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'cat_id': catId,
        'name': name,
        'type': type,
      };
}

class MapPoint {
  final int id;
  final int userId;
  final int catId;
  final int x;
  final int y;
  final String? img;
  final String? txt;

  MapPoint({
    required this.id,
    required this.userId,
    required this.catId,
    required this.x,
    required this.y,
    this.img,
    this.txt,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      catId: (json['cat_id'] as num?)?.toInt() ?? 0,
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      img: json['img']?.toString(),
      txt: json['txt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'cat_id': catId,
        'x': x,
        'y': y,
        if (img != null) 'img': img,
        if (txt != null) 'txt': txt,
      };
}
